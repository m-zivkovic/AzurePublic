import requests
import msal


APP_ID = ''
TENANT_ID = ''
SECRET_VALUE = ''
WORKSPACE_ID = ''
authority = f'https://login.microsoftonline.com/{TENANT_ID}'
scopes = ["https://analysis.windows.net/powerbi/api/.default"]

app = msal.ConfidentialClientApplication(APP_ID, authority=authority, client_credential=SECRET_VALUE)

result = None
result = app.acquire_token_for_client(scopes=scopes)

#print(result)

if not "access_token" in result:
    print(result.get("error"))
    print(result.get("error_description"))
    print(result.get("correlation_id"))
    raise Exception("Failed to get access token")



url_reports_list = f'https://api.powerbi.com/v1.0/myorg/groups/{WORKSPACE_ID}/reports'
headers = {
    'Authorization': 'Bearer ' + result['access_token']
}
response = requests.get(url_reports_list, headers=headers)
print(response.json())
