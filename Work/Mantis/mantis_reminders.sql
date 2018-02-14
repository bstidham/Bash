SET NOCOUNT ON;
USE CTWP_Prod;
;WITH ExcludeBugs AS (
    SELECT bug_id = NULL
)

, ExcludeProjects AS (
    SELECT Project = NULL
)

, D1 AS (
SELECT IssueLastUpdatedDate = IssueLastUpdatedDate.Item
     , IssueID = CONVERT(VARCHAR(7), Issue.ID)
     , IssueStatus = UPPER(ISNULL(LEFT(Stat.StatusName, 1), Issue.[status]))
     , IssueSummary = CONVERT(VARCHAR(50), REPLACE(Issue.summary, '|', ''))
     , NoteSubmittedDate = NoteSubmittedDate.Item
     , NoteSubmitter = CONVERT(VARCHAR(50), REPLACE(REPLACE('${realname}', '${realname}', ISNULL(NoteSubmitter.realname, NoteSubmitter.username)), '${username}', NoteSubmitter.username))
     , Note = CONVERT(VARCHAR(100), REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(200), NoteText.note), '|', ''), CHAR(10), ' '), CHAR(13), ''))
     , Seq = ROW_NUMBER() OVER (PARTITION BY Issue.ID ORDER BY Note.date_submitted DESC)
FROM (SELECT Username = 'bstidham') p
JOIN dbo.mantis_user_table Assignee
    ON  Assignee.username = p.username
JOIN dbo.mantis_bugnote_table Note
    ON  Note.note_type = 1 --reminder
    AND Note.note_attr LIKE REPLACE('%|uid|%', 'uid', Assignee.id)
JOIN dbo.mantis_bug_table  Issue
    ON  Issue.id = Note.bug_id
LEFT JOIN dbo.mantis_user_table NoteSubmitter
    ON  NoteSubmitter.id = Note.reporter_id
LEFT JOIN dbo.mantis_bugnote_text_table NoteText
    ON  NoteText.id = Note.bugnote_text_id
LEFT JOIN dbo.mantis_project_table mpt
    ON  mpt.id = Issue.project_id
CROSS APPLY Util.UnixDateTimeToDateTime(Issue.last_updated) IssueLastUpdatedDate
CROSS APPLY Util.UnixDateTimeToDateTime(Note.date_submitted) NoteSubmittedDate
LEFT JOIN pfi.Mantis_StatusEnum Stat
    ON  Stat.StatusID = Issue.[status]
LEFT JOIN ExcludeBugs eb 
    ON  eb.bug_id = Issue.id
LEFT JOIN ExcludeProjects ep
    On  ep.Project = mpt.name
WHERE eb.bug_id IS NULL 
  AND ep.Project IS NULL 
  AND (Stat.StatusName IS NULL OR Stat.StatusName <> 'Closed')
)

, D2 AS (
    SELECT TOP 10 d.*  
    FROM D1 d
    WHERE d.Seq = 1
    ORDER BY d.NoteSubmittedDate DESC
)

SELECT IssueLastUpdatedDate = CONVERT(VARCHAR(16), REPLACE(REPLACE('${d} ${t}', '${d}', CONVERT(VARCHAR(30), d.IssueLastUpdatedDate, 101)), '${t}', CONVERT(VARCHAR(30), d.IssueLastUpdatedDate, 108)))
     , d.IssueID
     , d.IssueStatus
     , d.IssueSummary
     , LastNoteSubmitter = d.NoteSubmitter
     , LastNote = d.Note
     , LastNoteSubmittedDate = CONVERT(VARCHAR(16), REPLACE(REPLACE('${d} ${t}', '${d}', CONVERT(VARCHAR(30), d.NoteSubmittedDate, 101)), '${t}', CONVERT(VARCHAR(30), d.NoteSubmittedDate, 108)))
     , ReplyDate = ISNULL(CONVERT(VARCHAR(16), REPLACE(REPLACE('${d} ${t}', '${d}', CONVERT(VARCHAR(30), reply.ReplyDate, 101)), '${t}', CONVERT(VARCHAR(30), reply.ReplyDate, 108))), '')
FROM D2 d
OUTER APPLY (
    SELECT ReplyDate = MAX(reply.ReplyDate) 
    FROM (
        SELECT ReplyDate = CASE WHEN ReplySubmittedDate.Item > d.NoteSubmittedDate THEN ReplySubmittedDate.Item ELSE NULL END
        FROM (SELECT Username = 'bstidham') p
        JOIN dbo.mantis_user_table Assignee
            ON  Assignee.username = p.username
        LEFT JOIN dbo.mantis_bugnote_table Note
            ON  Note.bug_id = d.IssueID
            AND Note.reporter_id = Assignee.id
        CROSS APPLY Util.UnixDateTimeToDateTime(Note.date_submitted) ReplySubmittedDate
    ) reply
) reply
ORDER BY d.NoteSubmittedDate 
