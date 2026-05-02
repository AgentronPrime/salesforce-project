public class AgentOptionResponse {

    // 1. Input Wrapper (required by Agentforce)
    public class RequestWrapper {
        @InvocableVariable(
            label='Customer Message'
            description='The initial message or greeting from the customer that triggers the quick options.'
            required=true
        )
        public String customerMessage;
    }

    // 2. Output Wrapper for options
    public class OptionData {
        @InvocableVariable(label='Option Text' description='Display label the customer sees as a selectable option.')
        public String label;

        public OptionData() {}

        public OptionData(String label) {
            this.label = label;
        }
    }

    // 3. Response Wrapper
    public class ResponseWrapper {
        @InvocableVariable(label='Options' description='List of quick-reply options returned to the customer.')
        public List<OptionData> options;

        @InvocableVariable(label='Welcome Message' description='Greeting message displayed to the customer.')
        public String welcomeMessage;

        public ResponseWrapper() {}

        public ResponseWrapper(List<OptionData> options, String welcomeMessage) {
            this.options = options;
            this.welcomeMessage = welcomeMessage;
        }
    }

    // 4. Invocable Method WITH input parameter
    @InvocableMethod(
        label='Get Test Drive Options'
        description='Accepts the customer message and returns static test drive menu options.'
    )
    public static List<ResponseWrapper> getTestDriveOptions(List<RequestWrapper> inputs) {
        List<ResponseWrapper> outputs = new List<ResponseWrapper>();

        if (inputs == null || inputs.isEmpty()) {
            return outputs;
        }

        // Static options — same for every invocation
        List<OptionData> options = new List<OptionData>();
        options.add(new OptionData('New customer?'));
        options.add(new OptionData('Book a test drive?'));
        options.add(new OptionData('Review my test drive..'));

        for (RequestWrapper wrapper : inputs) {
            if (wrapper == null) {
                continue;
            }
            String greeting = 'Hi there! Welcome to our chat support. Please select one of the options below to get started:';
            outputs.add(new ResponseWrapper(options, greeting));
        }

        return outputs;
    }
}