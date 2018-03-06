CREATE TABLE IF NOT EXISTS SummaryToProjectMap (
      SummaryToProjectMapID INTEGER PRIMARY KEY AUTOINCREMENT
    , SummaryMask TEXT NOT NULL UNIQUE
    , Project TEXT NOT NULL
    , ActivityStatusCode TEXT NOT NULL DEFAULT 'A'
    , CreatedDate TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    , ModifiedDate TEXT
);

INSERT INTO SummaryToProjectMap(SummaryMask, Project) VALUES('% - SUMMARY MASK HERE - %', 'PROJECT HERE');
REPEAT...
