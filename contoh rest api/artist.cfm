<!---
An example of writing REST web services in ColdFusion, without a framework (and why you should use one).
Provided as an example of a simple implementation, but should not be considered a best practice or something
I am promoting. Not thoroughly tested, not very maintainable, not even that reusable.
--->

<cfsetting enablecfoutputonly="true" showdebugoutput="false" />

<cffunction name="StructKeyRequire" output="false">
	<cfargument name="s" type="struct" />
	<cfargument name="k" type="string" />
	<cfset var local = {} />
	<cfloop list="#arguments.k#" index="local.i">
		<cfif not structKeyExists(s, local.i)>
			<cfthrow type="rest.invalidRequest" message="Required field `#local.i#` is missing from your request. Required fields for this action: `#arguments.k#`" />
		</cfif>
	</cfloop>
</cffunction>

<cftry>
	<!--- get verb --->
	<cfset verb = cgi.request_method />
	<cfset httpMethodOverride = GetPageContext().getRequest().getHeader("X-HTTP-Method-Override") />
	<cfif isDefined("httpMethodOverride")>
		<cfset verb = httpMethodOverride />
	</cfif>

	<!--- get url params --->
	<cfset params = {} />
	<cfset structAppend(params,url,true) />

	<!--- get request body --->
	<cfset requestBody = getHTTPRequestData().content />
	<cfif len(requestBody)>
		<cfset args = listToArray(requestBody,"&") />
		<cfloop from="1" to="#arrayLen(args)#" index="arg">
			<cfif findNoCase("=",args[arg])>
				<cfset params[listGetAt(args[arg],1,'=')] = listRest(args[arg],'=') />
			</cfif>
		</cfloop>
	</cfif>

	<!--- get headers --->
	<cfset headers = getHTTPRequestData().headers />

	<!--- get ID --->
	<cfif len(cgi.path_info)>
		<cfset params.id = listGetAt(cgi.path_info,1,'/') />
	</cfif>

	<!--- check for api key --->
	<cfif not structKeyExists(params, "apiKey")>
		<cfthrow type="rest.unauthorized" />
	</cfif>

	<!--- do stuff --->
	<cfswitch expression="#verb#">
		<cfcase value="get">
			<cfquery name="data" datasource="cfartgallery">
				select * from ARTISTS
				<cfif structKeyExists(params, "id")>
					where artistId = <cfqueryparam cfsqltype="cf_sql_numeric" value="#params.id#" />
				</cfif>
			</cfquery>
			<cfif data.recordCount eq 0>
				<cfthrow type="rest.notFound" />
			</cfif>
		</cfcase>
		<cfcase value="put">
			<cfthrow type="rest.methodNotAllowed" />
		</cfcase>
		<cfcase value="post">
			<cfset StructKeyRequire(params, "firstname,lastname,addres,city,state,postalcode,phone,email,fax,thepassword") />
			<cfquery name="doInsert" datasource="cfartgallery" result="insertResult">
				insert into ARTISTS (FIRSTNAME,LASTNAME,ADDRESS,CITY,STATE,POSTALCODE,PHONE,EMAIL,FAX,THEPASSWORD)
				values (
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#params.firstname#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.lastname#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.address#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.city#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.state#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.postalcode#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.phone#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.email#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.fax#" />
					, <cfqueryparam cfsqltype="cf_sql_varchar" value="#params.thepassword#" />
				)
			</cfquery>
			<cfheader statuscode="201" statustext="Created" />
			<cfcontent reset="true" type="application/json" />
			<!--- inserted id in sql server and apache derby --->
			<cfif structKeyExists(insertResult, "identitycol")>
				<cfheader name="x-inserted-id" value="#insertResult.identityCol#" />
			</cfif>
			<!--- inserted id in mysql --->
			<cfif structKeyExists(insertResult, "generated_key")>
				<cfheader name="x-inserted-id" value="#insertResult.generated_key#" />
			</cfif>
			<cfabort />
		</cfcase>
		<cfcase value="delete">
			<cfthrow type="rest.methodNotAllowed" />
		</cfcase>
	</cfswitch>

	<!--- serialize result --->
	<cfset output=serializeJson(data) />

	<!--- set return headers --->
	<cfheader statuscode="200" statustext="OK" />
	<cfcontent reset="true" type="application/json" />

	<!--- output return body --->
	<cfoutput>#output#</cfoutput>

	<!---
		handle potential errors
	--->
	<cfcatch type="rest.invalidRequest">
		<cfheader statuscode="400" statustext="Bad Request" />
		<cfcontent reset="true" type="application/json">
		<cfoutput>{"errors":["#cfcatch.message#"]}</cfoutput>
	</cfcatch>
	<cfcatch type="rest.unauthorized">
		<cfheader statuscode="401" statustext="Unauthorized" />
		<cfcontent reset="true" type="application/json">
		<cfoutput>{"errors":["API Key is required for all requests"]}</cfoutput>
	</cfcatch>
	<cfcatch type="rest.notFound">
		<cfheader statuscode="404" statustext="Not Found" />
		<cfcontent reset="true" type="application/json">
		<cfoutput>{"errors":["The ID you specified was not found"]}</cfoutput>
	</cfcatch>
	<cfcatch type="rest.methodNotAllowed">
		<cfheader statuscode="405" statustext="Method Not Allowed" />
		<cfcontent reset="true" type="application/json">
		<cfoutput>{"errors":["The method you used is now allowed for this resource"]}</cfoutput>
	</cfcatch>
</cftry>
