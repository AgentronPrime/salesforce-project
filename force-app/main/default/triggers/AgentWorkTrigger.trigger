/**
 * @description Trigger on AgentWork.
 *              Fires when Omni-Channel assigns/routes work to agent.
 *              This is the ONLY way to detect Omni-Channel assignments.
 */
trigger AgentWorkTrigger on AgentWork(after insert, after update) {
    AgentWorkTriggerHandler.execute(
        Trigger.new,
        Trigger.oldMap,
        Trigger.operationType
    );
}