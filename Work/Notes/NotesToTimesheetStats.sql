SELECT '{"Stats": {"Days": {' UNION ALL
SELECT GROUP_CONCAT('"' || e.DDD || '": "' || e.TSTotalTime || '"', ',')
FROM (SELECT e.DDD
	       , SUM(e.TSTime) TSTotalTime
	  FROM Entry e) e
GROUP BY e.DDD UNION ALL
SELECT '}}}';
