<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<cfparam name="webRoot"				type="string" default="#iif(lCase(cgi.https) IS 'on',de('https://'),de('http://'))##cgi.REMOTE_HOST##iif(cgi.SERVER_PORT NEQ 80,de(':#cgi.SERVER_PORT#'),de(''))#/" />
	<cfparam name="url.machine"		type="string" default="" />
	<cfparam name="url.statement"	type="string" default="" />
	<cfparam name="myPath"				type="string" default="#getDirectoryFromPath(getCurrentTemplatePath())#" />

	<cfset objSystem = createObject('component','config.system').init(myPath) />

	<cfoutput>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>#objSystem.getConfig('config.#myMachine#')# - [#objSystem.getConfig('config.#myMachine#')#]</title>
	<link rel="stylesheet" media="screen" href="#webroot#sdeploy/config/styles/screen.css" />

	<style type="text/css" media="screen">@import url("#webroot#sdeploy/config/styles/syntaxHighlighter.css");</style>

	<script type="text/javascript" src="#webroot#sdeploy/config/scripts/shCore.js"></script>
	<script type="text/javascript" src="#webroot#sdeploy/config/scripts/shBrushSql.js"></script>

	<script type="text/javascript">
		window.onload = function () {
		 dp.SyntaxHighlighter.ClipboardSwf = '#webroot#sdeploy/config/styles/clipboard.swf';
		 dp.SyntaxHighlighter.HighlightAll('code');
		}
	</script>
	</cfoutput>
</head>

<body style="margin:0; background-color:#e7e5dc">

<cfdirectory name="myStatements" action="list" directory="#myPath#" filter="*.sql" />

<div id="header" style="background:url('/eam_global/config/sql/images/columnheader.jpg'); height:22px; width:100%; font-family:arial;">
	<a href="index.cfm" style="float:left; color:yellow; text-decoration:none; position:relative; top:1px; left:3px;" title="HOME"><strong>Deployment-System from</strong></a> <span style="float:left; color:white; position:relative; left:8px;" title="your Machinename">[<cfoutput>#objSystem.getServerName()#</cfoutput>]</span>
	<img style="float:right; heigt:20px; width:20px;" src="/eam_global/config/sql/images/help.gif" onclick="window.open('config/help.cfm','helpsystem','');" />
</div>
<br />

<form action="index.cfm" method="get">
<cfoutput>
<cfif len(url.machine) AND len(url.statement)>
	<input type="submit" name="deploy" value="deploy" style="margin-left:15px; margin-right:2px;">
<cfelse><span style="margin-left:23px; margin-right:11px; position:relative; top:-2px; font-family:arial; font-size:13px;">deploy</span></cfif>
<select name="statement" onchange="self.location.href='index.cfm?<cfif len(url.machine)>machine=#url.machine#&</cfif>statement='+this.options[this.selectedIndex].value;">
	<option value="">SQL-Statement</option>
	<optgroup label="available Statements">
		<cfloop query="myStatements"><option value="#name#" <cfif name IS url.statement>selected</cfif>>#name#</option></cfloop>
	</optgroup>
</select>


<span style="position:relative; top:-3px;">@</span>
<select name="machine" onchange="self.location.href='index.cfm?machine='+this.options[this.selectedIndex].value<cfif len(url.statement)>+'&statement=#url.statement#'</cfif>;">
	<option value="">Machinename</option>
	<optgroup label="available Machines">
	<cfloop collection="#objSystem.getConfig('myServers')#" item="myMachine">
		<cfset mySelection = objSystem.getConfig('config.#myMachine#') />
		<option value="#myMachine#" <cfif myMachine IS url.machine>selected</cfif>><cfif myMachine IS objSystem.getServername()>local-Machine<cfelse>#myMachine#</cfif></option>
	</cfloop>
	</optgroup>
</select>

<a href="#cgi.SCRIPT_NAME#?#cgi.QUERY_STRING#" style="position:relative; left:5px; top:-2px;">reload statement</a>
</cfoutput>
</form>


<cfif len(url.machine) AND len(url.statement)>
	<cffile action="read" file="#myPath##url.statement#" variable="myQuerySQL" />
	<cfset getMyCode = objSystem.parseVARs(myQuerySQL,objSystem.getConfig('config.#url.machine#.database')) />

	<cfif isDefined('url.deploy')><!--- 0909-16:48 --->
		<cfset mySeperator = 651106 />
		<cfset mySearchPos	= 1 />

		<cftry>
			<cfset mySQLquery = replace(getMyCode,'#chr(13)##chr(10)#GO',mySeperator,'all')>

			<cfset mySQL = mid(mySQLquery,mySearchPos,find(mySeperator,mySQLquery,mySearchPos)-1) />
			<cfquery name="importSQL" datasource="#objSystem.getConfig('config.#url.machine#.odbc')#">
				#preservesinglequotes(mySQL)#
			</cfquery>
			<!--- <cfdump var="#mid(mySQLquery,mySearchPos,find(mySeperator,mySQLquery,mySearchPos)-1)#" /><br /><br /> --->
			<cfset mySearchPos = find(mySeperator,mySQLquery,mySearchPos) />
				<cftry>
					<cfloop condition="mySearchPos LTE len(mySQLquery)">
						<cfset mySQL = mid(mySQLquery,mySearchPos+6,find(mySeperator,mySQLquery,mySearchPos+6) -mySearchPos -6) />
						<cfquery name="importSQL" datasource="#objSystem.getConfig('config.#url.machine#.odbc')#">
							#preservesinglequotes(mySQL)#
						</cfquery>
						<!--- <cfdump var="#mid(mySQLquery,mySearchPos+6,find(mySeperator,mySQLquery,mySearchPos+6) -mySearchPos -6)#" /><br /><br /> --->
						<cfset mySearchPos = find(mySeperator,mySQLquery,find(mySeperator,mySQLquery,mySearchPos+6)) />
					</cfloop>
				<cfcatch></cfcatch>
				</cftry>
			<div style="position:absolute; left:530px; top:48px; font-family:courier;">
				<span style="color:green;">
					<strong> ... wurde erfolgreich importiert!</strong><br /><br />
				</span>
			</div>
		<cfcatch type="database">
			<div style="position:absolute; left:530px; top:48px; font-family:courier;">
				<span style="color:red;">
					<strong> ... konnte leider nicht importiert werden</strong><br /><br />
				</span>
			</div>
			<span style="color:blue; position:relative; left:15px;">
				<em>Error:</em> <cfoutput><cfif len(cfcatch.message)>#cfcatch.message#<br />
				</cfif>#cfcatch.detail#</cfoutput>
			</span>
		</cfcatch>
		</cftry>
	</cfif>

	<cfoutput><pre name="code" class="sql">#getMyCode#</pre></cfoutput>	<!--- <p style="font:normal normal normal 8px/1.5 courier;"></p> --->
</cfif>

</body>
</html>