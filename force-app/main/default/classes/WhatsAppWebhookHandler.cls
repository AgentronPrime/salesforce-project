@RestResource(urlMapping='/whatsapp/webhook/*')
global without sharing class WhatsAppWebhookHandler {
    
    private static final String VERIFY_TOKEN = 'Sai@1234';
    
    // ========================================
    // GET - Webhook Verification
    // ========================================
    
    @HttpGet
    global static void verifyWebhook() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String mode = req.params.get('hub.mode');
        String token = req.params.get('hub.verify_token');
        String challenge = req.params.get('hub.challenge');
        
        saveLog('Verification Request', 
                'Mode: ' + mode + '\nToken: ' + token + '\nChallenge: ' + challenge,
                'Verification');
        
        if (mode == 'subscribe' && token == VERIFY_TOKEN) {
            res.statusCode = 200;
            res.addHeader('Content-Type', 'text/plain');
            res.responseBody = Blob.valueOf(challenge);
            
            saveLog('Verification SUCCESS', 'Challenge returned: ' + challenge, 'Verification');
        } else {
            res.statusCode = 403;
            res.addHeader('Content-Type', 'text/plain');
            res.responseBody = Blob.valueOf('failed');
            
            saveLog('Verification FAILED', 'Token mismatch', 'Error');
        }
    }
    
    // ========================================
    // POST - Handle Incoming Messages
    // ========================================
    
    @HttpPost
    global static void handleIncomingMessage() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String requestBody = req.requestBody.toString();
        
        // Log raw payload
        saveLog('Raw Webhook Payload', requestBody, 'General');
        
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            List<Object> entryList = (List<Object>) payload.get('entry');
            
            if (entryList == null || entryList.isEmpty()) {
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('EVENT_RECEIVED');
                return;
            }
            
            for (Object entryObj : entryList) {
                Map<String, Object> entry = (Map<String, Object>) entryObj;
                List<Object> changes = (List<Object>) entry.get('changes');
                
                if (changes == null) continue;
                
                for (Object changeObj : changes) {
                    Map<String, Object> change = (Map<String, Object>) changeObj;
                    Map<String, Object> value = (Map<String, Object>) change.get('value');
                    
                    if (value == null) continue;
                    
                    // Process incoming messages
                    List<Object> messages = (List<Object>) value.get('messages');
                    if (messages != null && !messages.isEmpty()) {
                        processMessages(messages, value);
                    }
                    
                    // Process status updates
                    List<Object> statuses = (List<Object>) value.get('statuses');
                    if (statuses != null && !statuses.isEmpty()) {
                        processStatuses(statuses);
                    }
                }
            }
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('EVENT_RECEIVED');
            
        } catch (Exception e) {
            saveLog('Webhook Processing Error', 
                    'Error: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString(),
                    'Error');
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('EVENT_RECEIVED');
        }
    }
    
    // ========================================
    // Process Incoming Messages
    // ========================================
    
    private static void processMessages(List<Object> messages, Map<String, Object> value) {
        
        // Get sender contact info
        Map<String, String> contactNames = new Map<String, String>();
        List<Object> contacts = (List<Object>) value.get('contacts');
        if (contacts != null) {
            for (Object contactObj : contacts) {
                Map<String, Object> contact = (Map<String, Object>) contactObj;
                String waId = (String) contact.get('wa_id');
                Map<String, Object> profile = (Map<String, Object>) contact.get('profile');
                String name = (profile != null) ? (String) profile.get('name') : '';
                contactNames.put(waId, name);
            }
        }
        
        for (Object msgObj : messages) {
            Map<String, Object> message = (Map<String, Object>) msgObj;
            
            String messageId = (String) message.get('id');
            String fromNumber = (String) message.get('from');
            String messageType = (String) message.get('type');
            String senderName = contactNames.containsKey(fromNumber) ? 
                                contactNames.get(fromNumber) : 'Unknown';
            
            // Extract message body
            String messageBody = extractMessageBody(message, messageType);
            
            // Log incoming message
            saveLog('Incoming from +' + fromNumber, 
                    'Sender: ' + senderName + 
                    '\nType: ' + messageType + 
                    '\nMessage: ' + messageBody +
                    '\nMessage ID: ' + messageId,
                    'Incoming Message');
            
            // Find matching Contact
            Contact matchedContact = findContact(fromNumber);
            
            if (matchedContact != null) {
                saveLog('Contact Matched', 
                        'Contact: ' + matchedContact.Name + 
                        '\nPhone: +' + fromNumber,
                        'General');
            } else {
                saveLog('No Contact Found', 
                        'Phone: +' + fromNumber + 
                        '\nSender Name: ' + senderName,
                        'General');
            }
        }
    }
    
    // ========================================
    // Extract Message Body Based on Type
    // ========================================
    
    private static String extractMessageBody(Map<String, Object> message, String messageType) {
        
        String messageBody = '';
        
        if (messageType == 'text') {
            Map<String, Object> text = (Map<String, Object>) message.get('text');
            messageBody = (text != null) ? (String) text.get('body') : '';
            
        } else if (messageType == 'image') {
            Map<String, Object> image = (Map<String, Object>) message.get('image');
            messageBody = (image != null && image.get('caption') != null) ? 
                          (String) image.get('caption') : '[Image]';
                          
        } else if (messageType == 'document') {
            Map<String, Object> doc = (Map<String, Object>) message.get('document');
            messageBody = (doc != null && doc.get('filename') != null) ? 
                          'Document: ' + (String) doc.get('filename') : '[Document]';
                          
        } else if (messageType == 'audio') {
            messageBody = '[Audio Message]';
            
        } else if (messageType == 'video') {
            Map<String, Object> video = (Map<String, Object>) message.get('video');
            messageBody = (video != null && video.get('caption') != null) ? 
                          (String) video.get('caption') : '[Video]';
                          
        } else if (messageType == 'location') {
            Map<String, Object> location = (Map<String, Object>) message.get('location');
            if (location != null) {
                messageBody = 'Location: ' + location.get('latitude') + ', ' + location.get('longitude');
            }
            
        } else if (messageType == 'interactive') {
            Map<String, Object> interactive = (Map<String, Object>) message.get('interactive');
            if (interactive != null) {
                String interType = (String) interactive.get('type');
                if (interType == 'button_reply') {
                    Map<String, Object> btnReply = (Map<String, Object>) interactive.get('button_reply');
                    messageBody = 'Button: ' + (String) btnReply.get('title');
                } else if (interType == 'list_reply') {
                    Map<String, Object> listReply = (Map<String, Object>) interactive.get('list_reply');
                    messageBody = 'List: ' + (String) listReply.get('title');
                }
            }
        } else {
            messageBody = '[' + messageType + ' message]';
        }
        
        return messageBody;
    }
    
    // ========================================
    // Process Status Updates
    // ========================================
    
    private static void processStatuses(List<Object> statuses) {
        
        for (Object statusObj : statuses) {
            Map<String, Object> status = (Map<String, Object>) statusObj;
            
            String messageId = (String) status.get('id');
            String statusValue = (String) status.get('status');
            String recipientId = (String) status.get('recipient_id');
            
            saveLog('Status: ' + statusValue, 
                    'Message ID: ' + messageId + 
                    '\nRecipient: ' + recipientId,
                    'Status Update');
            
            if (statusValue == 'failed') {
                List<Object> errors = (List<Object>) status.get('errors');
                if (errors != null && !errors.isEmpty()) {
                    Map<String, Object> error = (Map<String, Object>) errors[0];
                    saveLog('Message FAILED', 
                            'Code: ' + error.get('code') + 
                            '\nTitle: ' + error.get('title'),
                            'Error');
                }
            }
        }
    }
    
    // ========================================
    // Find Contact by Phone Number
    // ========================================
    
    private static Contact findContact(String phoneNumber) {
        
        String cleanPhone = phoneNumber;
        if (cleanPhone.startsWith('+')) {
            cleanPhone = cleanPhone.substring(1);
        }
        
        String searchPhone = cleanPhone.right(10);
        
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, AccountId
            FROM Contact 
            WHERE Phone LIKE :('%' + searchPhone)
               OR MobilePhone LIKE :('%' + searchPhone)
            LIMIT 1
        ];
        
        return contacts.isEmpty() ? null : contacts[0];
    }
    
    // ========================================
    // Save Log to Custom Object
    // ========================================
    
    private static void saveLog(String subject, String details, String logType) {
        
        try {
            if (details != null && details.length() > 131000) {
                details = details.substring(0, 131000) + '... [TRUNCATED]';
            }
            
            if (subject != null && subject.length() > 255) {
                subject = subject.substring(0, 255);
            }
            
            Webhook_Log__c log = new Webhook_Log__c(
                Subject__c = subject,
                Details__c = details,
                Log_Type__c = logType
            );
            insert log;
            
        } catch (Exception e) {
            // Silently fail - don't break webhook
        }
    }
}