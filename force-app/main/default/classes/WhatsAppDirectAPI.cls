public class WhatsAppDirectAPI {
    
    // YOUR Phone Number ID (from Meta Business Settings)
    private static final String PHONE_NUMBER_ID = '1028994640302379';
    
    // YOUR Access Token (from Graph API Explorer)
    // ⚠️ Generate a new one - this one was shared publicly
    private static final String ACCESS_TOKEN = 'EAAX1tFZBSqhMBRa2H3ikCpFvrRvC29NdQ9OKDLUSLd870QVqtIavPko3eXgFFFNG026QeKARt4IWdHkBu6QOKgoG0x8mTZCwPpm2PCuGyWJ3KQSYyoSqSN7po7c867Di7z9T9qyvTl2ZBD0KhqI5486pP3QoZBgYUYo4TrfSroshyHT4fDgg2LAVDzWoggcXmIU0ZC2E1IbQSPtS1Ciyxa5IfUwS9dZAPAOCZCXsbMuoBhzNvKleeQ4GPaPldGv74RQnarSeLBh4bMb4O8ByRg2za3q';
    
    private static final String API_VERSION = 'v18.0';
    private static final String BASE_URL = 'https://graph.facebook.com/';
    
    // ========================================
    // INVOCABLE METHODS (Called from Flows)
    // ========================================
    
    /**
     * Send WhatsApp Text Message - Called from Flow
     */
    @InvocableMethod(label='Send WhatsApp Message' 
                     description='Send WhatsApp message via Meta API from +91 90321 47816')
    public static List<MessageResult> sendFromFlow(List<MessageRequest> requests) {
        
        List<MessageResult> results = new List<MessageResult>();
        
        for (MessageRequest req : requests) {
            MessageResult result = new MessageResult();
            
            try {
                // Validate inputs
                if (String.isBlank(req.phoneNumber)) {
                    result.success = false;
                    result.errorMessage = 'Phone number is required';
                    results.add(result);
                    continue;
                }
                
                if (String.isBlank(req.messageBody) && String.isBlank(req.templateName)) {
                    result.success = false;
                    result.errorMessage = 'Message body or template name is required';
                    results.add(result);
                    continue;
                }
                
                // Send message
                if (String.isNotBlank(req.templateName)) {
                    // Send template message
                    sendTemplateAsync(
                        req.phoneNumber, 
                        req.templateName, 
                        req.templateParameters
                    );
                } else {
                    // Send text message
                    sendTextAsync(req.phoneNumber, req.messageBody);
                }
                
                result.success = true;
                result.message = 'Message queued for ' + req.phoneNumber;
                
                // Log the message
                logMessageAsync(
                    req.phoneNumber, 
                    String.isNotBlank(req.messageBody) ? req.messageBody : 'Template: ' + req.templateName, 
                    'Outbound', 
                    req.contactId
                );
                
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = e.getMessage();
                System.debug(LoggingLevel.ERROR, 'WhatsApp Error: ' + e.getMessage());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // ========================================
    // TEXT MESSAGE
    // ========================================
    
    /**
     * Send text message asynchronously
     */
    @future(callout=true)
    public static void sendTextAsync(String phoneNumber, String messageBody) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => phone,
            'type' => 'text',
            'text' => new Map<String, Object>{
                'preview_url' => false,
                'body' => messageBody
            }
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        
        System.debug('Text Message Status: ' + res.getStatusCode());
        System.debug('Text Message Response: ' + res.getBody());
    }
    
    // ========================================
    // TEMPLATE MESSAGE
    // ========================================
    
    /**
     * Send template message asynchronously
     * Use this for messages outside 24-hour window
     */
    @future(callout=true)
    public static void sendTemplateAsync(String phoneNumber, String templateName, String parameters) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        // Build template components
        List<Map<String, Object>> components = new List<Map<String, Object>>();
        
        if (String.isNotBlank(parameters)) {
            List<Map<String, Object>> paramList = new List<Map<String, Object>>();
            
            for (String param : parameters.split(',')) {
                paramList.add(new Map<String, Object>{
                    'type' => 'text',
                    'text' => param.trim()
                });
            }
            
            components.add(new Map<String, Object>{
                'type' => 'body',
                'parameters' => paramList
            });
        }
        
        Map<String, Object> templateMap = new Map<String, Object>{
            'name' => templateName,
            'language' => new Map<String, Object>{
                'code' => 'en_US'
            }
        };
        
        if (!components.isEmpty()) {
            templateMap.put('components', components);
        }
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'to' => phone,
            'type' => 'template',
            'template' => templateMap
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        
        System.debug('Template Message Status: ' + res.getStatusCode());
        System.debug('Template Message Response: ' + res.getBody());
    }
    
    // ========================================
    // IMAGE MESSAGE
    // ========================================
    
    /**
     * Send image message
     */
    @future(callout=true)
    public static void sendImageAsync(String phoneNumber, String imageUrl, String caption) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => phone,
            'type' => 'image',
            'image' => new Map<String, Object>{
                'link' => imageUrl,
                'caption' => caption
            }
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        System.debug('Image Message Response: ' + res.getBody());
    }
    
    // ========================================
    // DOCUMENT MESSAGE
    // ========================================
    
    /**
     * Send document message
     */
    @future(callout=true)
    public static void sendDocumentAsync(String phoneNumber, String documentUrl, 
                                          String caption, String filename) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => phone,
            'type' => 'document',
            'document' => new Map<String, Object>{
                'link' => documentUrl,
                'caption' => caption,
                'filename' => filename
            }
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        System.debug('Document Message Response: ' + res.getBody());
    }
    
    // ========================================
    // INTERACTIVE BUTTON MESSAGE
    // ========================================
    
    /**
     * Send interactive button message
     */
    @future(callout=true)
    public static void sendButtonMessageAsync(String phoneNumber, String bodyText, 
                                                String buttonsJson) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        List<Object> buttons = (List<Object>) JSON.deserializeUntyped(buttonsJson);
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => phone,
            'type' => 'interactive',
            'interactive' => new Map<String, Object>{
                'type' => 'button',
                'body' => new Map<String, Object>{
                    'text' => bodyText
                },
                'action' => new Map<String, Object>{
                    'buttons' => buttons
                }
            }
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        System.debug('Button Message Response: ' + res.getBody());
    }
    
    // ========================================
    // MARK AS READ
    // ========================================
    
    /**
     * Mark incoming message as read
     */
    @future(callout=true)
    public static void markAsReadAsync(String messageId) {
        
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'status' => 'read',
            'message_id' => messageId
        };
        
        makeCallout(endpoint, JSON.serialize(payload));
    }
    
    // ========================================
    // NON-FUTURE METHODS (For direct calls)
    // ========================================
    
    /**
     * Send text message (non-future - use when not in trigger context)
     */
    public static String sendTextNow(String phoneNumber, String messageBody) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type' => 'individual',
            'to' => phone,
            'type' => 'text',
            'text' => new Map<String, Object>{
                'preview_url' => false,
                'body' => messageBody
            }
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> messages = (List<Object>) responseBody.get('messages');
            if (messages != null && !messages.isEmpty()) {
                Map<String, Object> msg = (Map<String, Object>) messages[0];
                return (String) msg.get('id');
            }
            return 'Success';
        } else {
            throw new WhatsAppException('Failed: ' + res.getBody());
        }
    }
    
    /**
     * Send template message (non-future)
     */
    public static String sendTemplateNow(String phoneNumber, String templateName, 
                                           List<String> parameters) {
        
        String phone = cleanPhoneNumber(phoneNumber);
        String endpoint = BASE_URL + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages';
        
        List<Map<String, Object>> components = new List<Map<String, Object>>();
        
        if (parameters != null && !parameters.isEmpty()) {
            List<Map<String, Object>> paramList = new List<Map<String, Object>>();
            for (String param : parameters) {
                paramList.add(new Map<String, Object>{
                    'type' => 'text',
                    'text' => param
                });
            }
            components.add(new Map<String, Object>{
                'type' => 'body',
                'parameters' => paramList
            });
        }
        
        Map<String, Object> templateMap = new Map<String, Object>{
            'name' => templateName,
            'language' => new Map<String, Object>{
                'code' => 'en_US'
            }
        };
        
        if (!components.isEmpty()) {
            templateMap.put('components', components);
        }
        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'to' => phone,
            'type' => 'template',
            'template' => templateMap
        };
        
        HttpResponse res = makeCallout(endpoint, JSON.serialize(payload));
        
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            return 'Success';
        } else {
            throw new WhatsAppException('Failed: ' + res.getBody());
        }
    }
    
    // ========================================
    // HELPER METHODS
    // ========================================
    
    /**
     * Make HTTP callout to Meta API
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
        return http.send(req);
    }
    
    /**
     * Clean phone number - remove special characters
     */
    private static String cleanPhoneNumber(String phone) {
        
        if (String.isBlank(phone)) {
            throw new WhatsAppException('Phone number cannot be empty');
        }
        
        // Remove everything except digits
        String cleaned = phone.replaceAll('[^0-9]', '');
        
        // Ensure it has country code
        // If starts with 0, remove it and add 91 (India)
        if (cleaned.startsWith('0')) {
            cleaned = '91' + cleaned.substring(1);
        }
        
        // If only 10 digits, assume India (+91)
        if (cleaned.length() == 10) {
            cleaned = '91' + cleaned;
        }
        
        return cleaned;
    }
    
    /**
     * Log outbound message to custom object
     */
    @future
    public static void logMessageAsync(String phoneNumber, String messageBody, 
                                         String direction, String contactId) {
        try {
            WhatsApp_Message__c msg = new WhatsApp_Message__c(
                Phone_Number__c = phoneNumber,
                Message_Body__c = messageBody,
                Direction__c = direction,
                Status__c = 'Sent',
                Contact__c = String.isNotBlank(contactId) ? contactId : null
            );
            insert msg;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Log Error: ' + e.getMessage());
        }
    }
    
    // ========================================
    // WRAPPER CLASSES
    // ========================================
    
    /**
     * Flow Input
     */
    public class MessageRequest {
        
        @InvocableVariable(label='Phone Number' required=true 
                          description='WhatsApp number e.g. +919876543210 or 9876543210')
        public String phoneNumber;
        
        @InvocableVariable(label='Message Body' required=false 
                          description='Text message to send')
        public String messageBody;
        
        @InvocableVariable(label='Template Name' required=false 
                          description='Template name e.g. hello_world')
        public String templateName;
        
        @InvocableVariable(label='Template Parameters' required=false 
                          description='Comma separated parameters for template')
        public String templateParameters;
        
        @InvocableVariable(label='Contact ID' required=false 
                          description='Salesforce Contact ID for logging')
        public String contactId;
    }
    
    /**
     * Flow Output
     */
    public class MessageResult {
        
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    /**
     * Custom Exception
     */
    public class WhatsAppException extends Exception {}
}