public without sharing class ElectraAgentTemplateController {

    // ── Response wrapper for LWC ─────────────────────────────────────
    public class TemplateResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  promptResponse;
        @AuraEnabled public String  errorMessage;
    }

    // ── Main method called from LWC ──────────────────────────────────
    // type            = 'Vehicle' | 'Dealer' | 'TestDrive'
    // vehicleModel    = model code  (only for Vehicle)
    // accountId       = dealer ID   (only for Dealer)
    // testDriveId     = TD record ID (only for TestDrive)
    @AuraEnabled(cacheable=false)
    public static TemplateResponse getReviewSummary(
        String type,
        String vehicleModel,
        String accountId,
        String testDriveId
    ) {
        TemplateResponse res = new TemplateResponse();

        try {
            // ── Build input map matching your prompt template inputs ──
            Map<String, String> inputParams = new Map<String, String>();
            inputParams.put('Type',                 type);
            inputParams.put('Vehicle_Model_Number', vehicleModel != null ? vehicleModel : '');
            inputParams.put('AccountId',            accountId   != null ? accountId   : '');
            inputParams.put('TestDriveId',          testDriveId != null ? testDriveId : '');

            // ── Call the Prompt Template via Connect API ─────────────
            // Template API name must match exactly what you saved in Setup
            // Go to: Setup → Prompt Builder → Your Template → API Name
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            promptInput.additionalConfig =
                new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptInput.additionalConfig.applicationName =
                'PromptBuilderPreview';

            // Build input values map
            Map<String, ConnectApi.WrappedValue> valuesMap =
                new Map<String, ConnectApi.WrappedValue>();

            for (String key : inputParams.keySet()) {
                ConnectApi.WrappedValue wv = new ConnectApi.WrappedValue();
                wv.value = inputParams.get(key);
                valuesMap.put('Input:' + key, wv);
            }

            promptInput.inputParams  = valuesMap;
            promptInput.isPreview    = false;

            // ── YOUR PROMPT TEMPLATE API NAME ────────────────────────
            // Replace 'Electra_Agent_Template' with the exact API name
            // from Setup → Prompt Builder → Electra Agent Template
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Electra_Agent_Template',
                    promptInput
                );

            // ── Extract the text from the response ───────────────────
            if (result != null
                && result.generations != null
                && !result.generations.isEmpty()) {

                ConnectApi.EinsteinLLMGenerationItemOutput gen =
                    result.generations[0];

                res.success        = true;
                res.promptResponse = gen.text;
                res.errorMessage   = '';

            } else {
                res.success        = false;
                res.promptResponse = '';
                res.errorMessage   = 'No response returned from prompt template.';
            }

        } catch (Exception e) {
            res.success        = false;
            res.promptResponse = '';
            res.errorMessage   = 'Error: ' + e.getMessage();
        }

        return res;
    }
}