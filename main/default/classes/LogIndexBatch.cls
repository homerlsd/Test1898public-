public without sharing class LogIndexBatch extends DatabaseUtils.PharosBatchImpl implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts,Database.RaisesPlatformEvents {

    public enum JobType {INIT_INDEXES_BATCH, UPDATE_INTERNAL_FIELD_BATCH}
    private JobType runJobType;

    private static LogIndexBatch instance = null;

    public static LogIndexBatch getInstance(JobType jobType) {
        if (instance == null) {
            instance = new LogIndexBatch(jobType, Logger.getInstance());
        }
        return instance;
    }

    private LogIndexBatch(JobType jobType, Logger logger) {
        super(logger);
        this.runJobType = jobType;
        BATCH_SCOPE = 200;
    }

    public override void startBatch() {
        DatabaseUtils.executeBatchWithLimitCheck('LogIndexBatch', this);
    }

    public override Boolean initialValidation() {
        if (runJobType == LogIndexBatch.JobType.UPDATE_INTERNAL_FIELD_BATCH) {
            return [SELECT COUNT() FROM Log_Index__c WHERE Internal__c = TRUE LIMIT 1] == 0;
        }
        return true;
    }

    public override Integer getIterationsCount() {
        return [SELECT COUNT() FROM Log__c WHERE Hash_1__c != NULL];
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([
            SELECT 
                Id, Hash_1__c, Organization_Id__c, Bug_Tracker__c, First_Occurred_On__c, Resolved_On__c, Created_At__c, Area__c, Category__c
            FROM Log__c
            WHERE Hash_1__c != NULL
		]);
	}

    public void execute(Database.BatchableContext BC, List<Log__c> scope) {
        List<Log__c> logs = (List<Log__c>)scope;
        if (!logs.isEmpty()) {
            Set<String> logIndexKeys = new Set<String>();
            for (Log__c log : logs) {
                logIndexKeys.add(ConfigUtil.getLogIndexKey(log?.Hash_1__c, log?.Organization_Id__c));
            }
            ConfigUtil.LogIndexHelper helper = new ConfigUtil.LogIndexHelper(logIndexKeys);
            if (this.runJobType == JobType.INIT_INDEXES_BATCH) {
                for (Log__c log : logs) {
                    ConfigUtil.LogIndex index = helper.getLogIndex(log);
                    if (index == null) {
                        index = helper.createLogIndex(log);
                    }
                    if (log.First_Occurred_On__c != null && log.First_Occurred_On__c < index.firstOccurredOn) {
                        index.firstOccurredOn = log.First_Occurred_On__c;
                    }
                    if (log.Resolved_On__c != null && (log.Resolved_On__c > index.resolvedOn || index.resolvedOn == null)) {
                        index.resolvedOn = log.Resolved_On__c;
                    }
                    if (log.Bug_Tracker__c != null) {
                        index.bugTracker = log.Bug_Tracker__c;
                    }
                    helper.updateLogIndex(index);
                }
            }
            if (this.runJobType == JobType.UPDATE_INTERNAL_FIELD_BATCH) {
                for (Log__c log : logs) {
                    ConfigUtil.LogIndex index = helper.getLogIndex(log);
                    if (log?.Category__c == 'Pharos Error' || log.Area__c == 'Pharos') {
                        index.internal = true;
                    }
                    if (index != null) helper.updateLogIndex(index);
                }
            }
            helper.saveLogIndexes(this.loggerInstance);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        this.loggerInstance?.flush();
    }
}