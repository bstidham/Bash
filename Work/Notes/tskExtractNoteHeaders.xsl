<?xml version="1.0"?>
<stylesheet version="1.0"
	xmlns="http://www.w3.org/1999/XSL/Transform">
	<param name="analysis_date">PLACEHOLDER</param>
	<output method="text"/>
	<template match="/">
		<!-- <apply-templates select='/tasks/task/task[starts-with(@duedate, $analysis_date)]'> -->
		<apply-templates select='/tasks/task/task[(not(@completiondate) or @completiondate = "")]'>
			<sort select="@duedate"/>
		</apply-templates>
	</template>
	<template match="task">
		<text>INSERT INTO task_header (TaskID, Subject, DueDate, Description) VALUES ('</text>
		<value-of select="@id"/>
		<text>', '</text>
		<value-of select="@subject"/>
		<text>', '</text>
		<value-of select="@duedate"/>
		<text>', '</text>
		<value-of select="./description"/>
		<text>');&#xa;</text>
	</template>
</stylesheet>
