public class WhatsAppService {
    
    // Store these in Custom Metadata or Named Credentials
    private static final String WHATSAPP_API_URL = 'https://graph.facebook.com/v18.0/';
    private static final String PHONE_NUMBER_ID = 'YOUR_PHONE_NUMBER_ID'; 
    // Use Named Credential or Custom Metadata for token
    private static final String ACCESS_TOKEN = 'YOUR_PERMANENT_ACCESS_TOKEN';
    
    /**
     * Send a text message via WhatsApp
     */
    public static WhatsAppResponse sendTextMessage(String toPhoneNumber, String messageBody) {
        
        String endpoint = WHATSAPP_API_URL + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => toPhoneNumber,
            'type' => 'text',
            'text' => new Map<String, Object>{
                'preview_url' => false,
                'body' => messageBody
            }
        };
        
        HttpResponse response = makeCallout(endpoint, JSON.serialize(payload));
        WhatsAppResponse waResponse = parseResponse(response);
        
        // Log the message
        if (waResponse.success) {
            logMessage(toPhoneNumber, messageBody, 'Outbound', 'Sent', waResponse.messageId);
        } else {
            logMessage(toPhoneNumber, messageBody, 'Outbound', 'Failed', null);
        }
        
        return waResponse;
    }
    
    /**
     * Send a template message via WhatsApp
     */
    public static WhatsAppResponse sendTemplateMessage(String toPhoneNumber, String templateName, 
                                                         String languageCode, List<String> parameters) {
        
        String endpoint = WHATSAPP_API_URL + PHONE_NUMBER_ID + '/messages';
        
        // Build parameters list
        List<Map<String, Object>> componentParameters = new List<Map<String, Object>>();
        if (parameters != null && !parameters.isEmpty()) {
            for (String param : parameters) {
                componentParameters.add(new Map<String, Object>{
                    'type' => 'text',
                    'text' => param
                });
            }
        }
        
        // Build components
        List<Map<String, Object>> components = new List<Map<String, Object>>();
        if (!componentParameters.isEmpty()) {
            components.add(new Map<String, Object>{
                'type' => 'body',
                'parameters' => componentParameters
            });
        }
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => toPhoneNumber,
            'type' => 'template',
            'template' => new Map<String, Object>{
                'name' => templateName,
                'language' => new Map<String, Object>{
                    'code' => languageCode
                },
                'components' => components
            }
        };
        
        HttpResponse response = makeCallout(endpoint, JSON.serialize(payload));
        WhatsAppResponse waResponse = parseResponse(response);
        
        if (waResponse.success) {
            logMessage(toPhoneNumber, 'Template: ' + templateName, 'Outbound', 'Sent', waResponse.messageId);
        }
        
        return waResponse;
    }
    
    /**
     * Send an image message via WhatsApp
     */
    public static WhatsAppResponse sendImageMessage(String toPhoneNumber, String imageUrl, String caption) {
        
        String endpoint = WHATSAPP_API_URL + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => toPhoneNumber,
            'type' => 'image',
            'image' => new Map<String, Object>{
                'link' => imageUrl,
                'caption' => caption
            }
        };
        
        HttpResponse response = makeCallout(endpoint, JSON.serialize(payload));
        return parseResponse(response);
    }
    
    /**
     * Send a document message via WhatsApp
     */
    public static WhatsAppResponse sendDocumentMessage(String toPhoneNumber, String documentUrl, 
                                                         String caption, String filename) {
        
        String endpoint = WHATSAPP_API_URL + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => toPhoneNumber,
            'type' => 'document',
            'document' => new Map<String, Object>{
                'link' => documentUrl,
                'caption' => caption,
                'filename' => filename
            }
        };
        
        HttpResponse response = makeCallout(endpoint, JSON.serialize(payload));
        return parseResponse(response);
    }
    
    /**
     * Send interactive button message
     */
    public static WhatsAppResponse sendInteractiveButtonMessage(String toPhoneNumber, String bodyText, 
                                                                  List<Map<String, String>> buttons) {
        
        String endpoint = WHATSAPP_API_URL + PHONE_NUMBER_ID + '/messages';
        
        List<Map<String, Object>> buttonList = new List<Map<String, Object>>();
        for (Map<String, String> btn : buttons) {
            buttonList.add(new Map<String, Object>{
                'type' => 'reply',
                'reply' => new Map<String, Object>{
                    'id' => btn.get('id'),
                    'title' => btn.get('title')
                }
            });
        }
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => toPhoneNumber,
            'type' => 'interactive',
            'interactive' => new Map<String, Object>{
                'type' => 'button',
                'body' => new Map<String, Object>{
                    'text' => bodyText
                },
                'action' => new Map<String, Object>{
                    'buttons' => buttonList
                }
            }
        };
        
        HttpResponse response = makeCallout(endpoint, JSON.serialize(payload));
        return parseResponse(response);
    }
    
    /**
     * Mark message as read
     */
    public static void markMessageAsRead(String messageId) {
        
        String endpoint = WHATSAPP_API_URL + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'status' => 'read',
            'message_id' => messageId
        };
        
        makeCallout(endpoint, JSON.serialize(payload));
    }
    
    /**
     * HTTP Callout helper
     */
    private static HttpResponse makeCallout(String endpoint, String body) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
        req.setBody(body);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('WhatsApp API Response Status: ' + res.getStatusCode());
        System.debug('WhatsApp API Response Body: ' + res.getBody());
        
        return res;
    }
    
    /**
     * Parse API Response
     */
    private static WhatsAppResponse parseResponse(HttpResponse response) {
        
        WhatsAppResponse waResponse = new WhatsAppResponse();
        
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            waResponse.success = true;
            
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> messages = (List<Object>) responseBody.get('messages');
            
            if (messages != null && !messages.isEmpty()) {
                Map<String, Object> firstMessage = (Map<String, Object>) messages[0];
                waResponse.messageId = (String) firstMessage.get('id');
            }
        } else {
            waResponse.success = false;
            waResponse.errorMessage = response.getBody();
            System.debug(LoggingLevel.ERROR, 'WhatsApp API Error: ' + response.getBody());
        }
        
        return waResponse;
    }
    
    /**
     * Log message to Salesforce
     */
    @future
    public static void logMessage(String phoneNumber, String messageBody, String direction, 
                                   String status, String whatsappMessageId) {
        
        // Find associated Contact
        Contact relatedContact = findContactByPhone(phoneNumber);
        
       /* WhatsApp_Message__c msg = new WhatsApp_Message__c(
            Phone_Number__c = phoneNumber,
            Message_Body__c = messageBody,
            Direction__c = direction,
            Status__c = status,
            WhatsApp_Message_Id__c = whatsappMessageId,
            Contact__c = relatedContact?.Id
        );*/
        
       // insert msg;
    }
    
    /**
     * Find Contact by Phone Number
     */
    public static Contact findContactByPhone(String phoneNumber) {
        
        // Clean phone number - remove country code prefix if needed
        String cleanPhone = phoneNumber;
        if (cleanPhone.startsWith('+')) {
            cleanPhone = cleanPhone.substring(1);
        }
        
        List<Contact> contacts = [
            SELECT Id, Name, Phone, MobilePhone 
            FROM Contact 
            WHERE Phone LIKE :('%' + cleanPhone.right(10))
               OR MobilePhone LIKE :('%' + cleanPhone.right(10))
            LIMIT 1
        ];
        
        return contacts.isEmpty() ? null : contacts[0];
    }
    
    /**
     * Response wrapper class
     */
    public class WhatsAppResponse {
        public Boolean success { get; set; }
        public String messageId { get; set; }
        public String errorMessage { get; set; }
        
        public WhatsAppResponse() {
            this.success = false;
        }
    }
}