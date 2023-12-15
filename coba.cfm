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

  <!--- generate jwt --->
  <cfset somePayload = {
      "sub": "1234567890",
      "name": "John Doe",
      "admin": true
    }>

  <cfset jwt = createObject("component", "JsonWebTokens")>
  <cfset token = jwt.encode( somePayload, "HS256", "secretKey" )>

  <cfoutput>
    #params.apiKey#
  </cfoutput>
  <!--- <cfset data={
    "error":false,
    "message": "Sucess get data",
    "token":token,
    "data":[
      {"Id":101,"Name":"John Adams","Paid":FALSE},  
      {"Id":102,"Name":"Samuel Jackson","Paid":TRUE},  
      {"Id":103,"Name":"Jack Michaels","Paid":TRUE},  
      {"Id":104,"Name":"Tony Stark","Paid":FALSE}  
    ]
  }> --->

  <cfset decode= jwt.decode(token, "HS256", "secretKey")>

  <cfset data={
    "error":false,
    "message": "Sucess get data",
    "token":token,
    "decode":decode
  }>


  <cfswitch expression="#verb#">
    <!--- get method --->
    <cfcase value="get">
      ini get method
    </cfcase>
    <!--- put method --->
    <cfcase value="put">
      ini put method
    </cfcase>
    <!--- post method --->
    <cfcase value="post">
      ini post method
    </cfcase>
    <!--- delete method --->
    <cfcase value="delete">
      ini delete method
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