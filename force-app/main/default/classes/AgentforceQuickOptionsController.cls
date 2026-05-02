/**
 * Supplies predefined quick-reply options for the Agentforce / Experience chat.
 * The agent invokes this action when a customer initiates a conversation,
 * and presents the returned options for the customer to select and move forward.
 *
 * Invocable: callable from Flows, Agents, and the /actions/custom REST endpoint.
 * AuraEnabled: callable from LWCs via @wire or imperative Apex.
 */
public with sharing class AgentforceQuickOptionsController {

    // ─── Invocable Wrapper (Output Only) ──────────────────────────────

    public class ResponseWrapper {
        @InvocableVariable(
            label='Quick Options'
            description='Predefined quick-reply options the customer can select to move forward.'
        )
        public List<QuickOption> options;

        @InvocableVariable(
            label='Welcome Message'
            description='A greeting message displayed to the customer along with the options.'
        )
        public String welcomeMessage;

        @InvocableVariable(
            label='Option Count'
            description='Total number of quick options returned.'
        )
        public Integer optionCount;

        public ResponseWrapper() {}

        public ResponseWrapper(
            List<QuickOption> options,
            String welcomeMessage
        ) {
            this.options = options;
            this.welcomeMessage = welcomeMessage;
            this.optionCount = (options != null) ? options.size() : 0;
        }
    }

    // ─── Invocable Method (Flows / Agents) ────────────────────────────

    @InvocableMethod(
        label='Get Customer Quick Options'
        description='Returns predefined quick-reply options for the customer to select.'
    )
    public static List<ResponseWrapper> getQuickOptionsInvocable() {
        List<ResponseWrapper> outputs = new List<ResponseWrapper>();

        List<QuickOption> options = buildQuickOptions();
        String greeting = buildWelcomeMessage();

        outputs.add(new ResponseWrapper(options, greeting));

        return outputs;
    }

    // ─── Private Helpers ─────────────────────────────────────────────

    private static List<QuickOption> buildQuickOptions() {
        return new List<QuickOption>{
            new QuickOption(
                '1',
                'New customer?',
                'I am a new customer and need help getting started.'
            ),
            new QuickOption(
                '2',
                'Book a test drive',
                'I want to book a test drive. Please help me with model, date and time, and my zip code.'
            ),
            new QuickOption(
                '3',
                'Review my test drive',
                'I would like to leave a review for my test drive experience.'
            )
        };
    }

    private static String buildWelcomeMessage() {
        return 'Hi there! Welcome to our chat support. Please select one of the options below to get started:';
    }

    // ─── Inner DTO ───────────────────────────────────────────────────

    public class QuickOption {
        @AuraEnabled
        @InvocableVariable(
            label='Id'
            description='Unique identifier for the option the customer selects.'
        )
        public String id;

        @AuraEnabled
        @InvocableVariable(
            label='Label'
            description='Display label the customer sees as a selectable option.'
        )
        public String label;

        @AuraEnabled
        @InvocableVariable(
            label='Message'
            description='Seed message sent to the agent when the customer selects this option.'
        )
        public String message;

        // Required no-arg constructor for invocable deserialization.
        public QuickOption() {}

        public QuickOption(String id, String label, String message) {
            this.id = id;
            this.label = label;
            this.message = message;
        }
    }
}