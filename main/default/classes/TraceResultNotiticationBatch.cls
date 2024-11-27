public with sharing class TraceResultNotiticationBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts,Database.RaisesPlatformEvents{

    private Logger logger;
    private NotificationService notificationService;

    public TraceResultNotiticationBatch(Logger logger) {
        this.logger = logger;
        this.notificationService = new NotificationService(TraceResultNotiticationBatch.class.getName(), logger);
    }

    public static void startTraceResultNotiticationBatch() {
        NotificationService.getInstance(NotificationService.NOTIFICATION_SERVICE_TYPE.TRACE_RESULT, null).startNotificationBatch();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return this.notificationService.getQueryLocator();
    }

    public void execute(Database.BatchableContext info, List<SObject> scope) {
        this.notificationService.batchExecuteIteration(info, scope);
    }

    public void finish(Database.BatchableContext info) {
        if (!Test.isRunningTest()) {
            this.notificationService.startNotificationBatch();
            this.logger?.flush();
        }
    }
}