public class WhatsAppFreeFormService {

    @future(callout=true)
    public static void sendFreeFormMessage(
        String recipientPhone,
        String messageText
    ) {
       // WhatsApp_Config__mdt config = WhatsApp_Config__mdt.getInstance('Default');

        String endpoint = 'https://graph.facebook.com/' + 'v25.0'
                        + '/' +'1028994640302379'+ '/messages';

        // FREE FORM - No template needed
        Map<String, Object> body = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'to' => recipientPhone,
            'type' => 'text',
            'text' => new Map<String, Object>{
                'body' => messageText
            }
        };
         String token='EAAX1tFZBSqhMBRdUX72hSTzNPkVlg546ZCXT6QjBnchkFV9SYlpM6gVW6ZBZAKhrzb9kKK8UFI0E9GZBZAtXUrZANiiuaAU2TkGNB4q2qvFtXfE2nFHC8SQBH6NEc0fIWq3Uq3kC8CMzzJsahyD5HKHN98fCrfIEsxKu1KZBIZClTPe2Dls6oKvFjZAxXSen5rsC0rWAZDZD';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Response: ' + res.getStatusCode() + ' | ' + res.getBody());
    }
}