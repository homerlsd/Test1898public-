@IsTest
private class LogServiceBatchTest {

    @TestSetup
    private static void testSetup() {
        Logger_Settings__c settings = Logger_Settings__c.getOrgDefaults();
        settings.Service_Scheduler_Enabled__c = true;
        insert settings;

        TestDataFactory.createConnectedOrgSettings();
        TestDataFactory.createConnectedOrg();
    }

    @IsTest
    public static void test_metrics_batch_feature_parameter2() {
        Integer metrics2 = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_6_NAME);
        Test.startTest();

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put(getPlatformEventConfigMockURL(), getPlatformEventConfigMock());
        HttpCalloutMock multiCalloutMock = new TestDataFactory.MultiRequestMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        List<MetadataService.CaseSettings> records = new List<MetadataService.CaseSettings>();
        MetadataService.CaseSettings settings = new MetadataService.CaseSettings();
        settings.emailToCase = new MetadataService.EmailToCaseSettings();
        settings.emailToCase.enableEmailToCase = false;
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(records));

        MetricsBatch.calculateOrgMetrics2();
        Test.stopTest();
        Integer metrics2After = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_6_NAME);
        System.assertNotEquals(metrics2, metrics2After);
    }

    @IsTest
    public static void test_metrics_batch_feature_parameter1() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            TestDataFactory.createTestNotificationLog();
        }
        Integer metrics1 = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_5_NAME);

        Test.startTest();
        MetricsBatch.calculateOrgMetrics();
        Test.stopTest();
        Integer metrics1After = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_5_NAME);
        System.assertNotEquals(metrics1, metrics1After);
    }

    @IsTest
    public static void test_metrics_batch_feature_parameter3() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            TestDataFactory.createTestNotificationLog();
        }
        Integer metrics3 = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_7_NAME);

        Test.startTest();
        MetricsBatch.calculateOrgMetrics3();
        Test.stopTest();
        Integer metrics3After = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_7_NAME);
        System.assertNotEquals(metrics3, metrics3After);
    }

    @IsTest
    public static void test_metrics_batch_feature_parameter4() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            TestDataFactory.createTestNotificationLog();
        }
        Integer metrics4 = null;

        Test.startTest();
        MetricsBatch.calculateOrgMetrics4();
        Test.stopTest();
        Integer metrics4After = FeatureManagement.checkPackageIntegerValue(PermissionsUtil.FEATURE_PARAM_MAP_8_NAME);
        System.assertNotEquals(metrics4, metrics4After);
    }

    @IsTest
    public static void test_scheduler() {
        Test.startTest();
        Datetime dt = Datetime.now().addSeconds(30);
        String cronExp = dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('testLogServiceScheduler', cronExp, new LogServiceScheduler());
        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, cronTrigger.CronExpression);
        System.assertEquals(0, cronTrigger.TimesTriggered);
        System.assertEquals(dt, cronTrigger.NextFireTime);
        Test.stopTest();
    }

    @IsTest
    private static void test_batch_error_handler() {
        Log__c log = new Log__c();
        log.Hash_1__c = 'hash1';
        log.Organization_Id__c = UserInfo.getOrganizationId().left(15);
        log.Post_Processing_Status__c = LogPostProcessingService.POST_PROCESSING_STATUS_EXECUTED;
        insert log;

        Test.startTest();
        LogPostProcessingBatch.getInstance().startBatch();
        Test.stopTest();

        log = [SELECT Post_Processing_Status__c FROM Log__c WHERE Id = :log.Id LIMIT 1];
        System.assertEquals(LogPostProcessingService.POST_PROCESSING_STATUS_FAILED, log.Post_Processing_Status__c);
    }

    @IsTest
    private static void test_batch_error_handler_flow_type() {
        Log__c log = new Log__c();
        log.Hash_1__c = 'hash1';
        log.Category__c = FlowExceptionParser.FLOW_CATEGORY;
        log.Area__c = FlowExceptionParser.FLOW_CATEGORY;
        log.Stacktrace__c = 'abrakadabra';
        log.Organization_Id__c = UserInfo.getOrganizationId().left(15);
        log.Post_Processing_Status__c = LogPostProcessingService.POST_PROCESSING_STATUS_NEEDED;
        insert log;

        Test.startTest();
        LogPostProcessingBatch.getInstance().startBatch();
        Test.stopTest();

        log = [SELECT Post_Processing_Status__c, Stacktrace_Parse_Result__c FROM Log__c WHERE Id = :log.Id LIMIT 1];
        System.assertEquals(LogPostProcessingService.POST_PROCESSING_STATUS_FAILED, log.Post_Processing_Status__c);
        System.assertEquals(JSON.serialize(null), log.Stacktrace_Parse_Result__c);
    }

    @IsTest
    private static void test_post_processing_batch_process_builder() {
        test_post_processing_batch(FlowExceptionParser.PROCESS_BUILDER_CATEGORY);
    }

    @IsTest
    private static void test_post_processing_batch_flow() {
        test_post_processing_batch(FlowExceptionParser.FLOW_CATEGORY);
    }

    @IsTest
    private static void test_post_processing_batch_integration() {
        test_post_processing_batch(LogPostProcessingService.CATEGORY_INTEGRATION);
    }

    @IsTest
    private static void test_post_processing_batch_bulk() {
        test_post_processing_batch(BulkAPIJobBatchService.BULK_API);
    }

    @IsTest
    private static void test_post_processing_batch_other() {
        test_post_processing_batch('Other');
    }

    private static void test_post_processing_batch(String category) {
        Test.startTest();
        Log__c log = new Log__c();
        log.Hash_1__c = 'hash1';
        log.Category__c = category;
        log.Type__c = 'Custom';
        log.Organization_Id__c = UserInfo.getOrganizationId().left(15);
        log.Post_Processing_Status__c = LogPostProcessingService.POST_PROCESSING_STATUS_NEEDED;
        insert log;


        LogPostProcessingBatch.getInstance().startBatch();
        Test.stopTest();

        log = [SELECT Post_Processing_Status__c FROM Log__c WHERE Id = :log.Id LIMIT 1];
        System.assertEquals(LogPostProcessingService.POST_PROCESSING_STATUS_FAILED, log.Post_Processing_Status__c);
    }

    @IsTest
    public static void test_batch_positive() {
        test_batch(true);
    }

    @IsTest
    public static void test_batch_negative() {
        test_batch(false);
    }

    private static void test_batch(Boolean isPositive) {
        Test.startTest();
        updateConnectedOrg();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('https://test_Identity_Url', isPositive ? getIdentityMock() : invalidGrantMock());
        HttpCalloutMock multiCalloutMock = new TestDataFactory.MultiRequestMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        LogServiceBatch.getInstance().startBatch();
        Test.stopTest();
        List<Connected_Org__c> lstConnectedOrgs = [SELECT Id, Access_Token__c FROM Connected_Org__c LIMIT 1];
        if (!lstConnectedOrgs.isEmpty()) {
            System.assertEquals('test_Access_Token', lstConnectedOrgs[0].Access_Token__c);
        }
    }

    @IsTest
    public static void test_batch_refresh_token_positive() {
        test_batch_refresh_token(true);
    }

    @IsTest
    public static void test_batch_refresh_token_negative() {
        test_batch_refresh_token(false);
    }

    private static void test_batch_refresh_token(Boolean isPositive) {
        Test.startTest();
        updateConnectedOrg();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('https://test_Identity_Url', badOAuthTokenMock());
        endpoint2TestResp.put('https://test_Instance_Url' + ConfigUtil.SF_OAUTH_TOKEN_ENDPOINT, isPositive ? refreshTokenMock() : invalidGrantMock());
        HttpCalloutMock multiCalloutMock = new TestDataFactory.MultiRequestMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        LogServiceBatch.getInstance().startBatch();
        Test.stopTest();
        List<Connected_Org__c> lstConnectedOrgs = [SELECT Id, Access_Token__c FROM Connected_Org__c LIMIT 1];
        if (!lstConnectedOrgs.isEmpty()) {
            if (isPositive) {
                System.assertEquals('test_new_Access_Token', lstConnectedOrgs[0].Access_Token__c);
            } else {
                System.assertEquals('test_Access_Token', lstConnectedOrgs[0].Access_Token__c);
            }
        }
    }

    private static void updateConnectedOrg() {
        List<Connected_Org__c> lstConnectedOrgs = [SELECT Id, Scheduler_Enabled__c FROM Connected_Org__c LIMIT 1];
        if (!lstConnectedOrgs.isEmpty()) {
            lstConnectedOrgs[0].Scheduler_Enabled__c = true;
            update lstConnectedOrgs;
        }
    }

    private static TestDataFactory.SingleRequestMock getIdentityMock() {
        TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
                200,
                'OK',
                '{}'
        );
        return singleRequestMock;
    }

    private static TestDataFactory.SingleRequestMock refreshTokenMock() {
        ConnectedOrgService.AuthTokenResponse authTokenResponse = new ConnectedOrgService.AuthTokenResponse();
        authTokenResponse.access_token = 'test_new_Access_Token';
        TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
                200,
                'OK',
                JSON.serialize(authTokenResponse)
        );
        return singleRequestMock;
    }

    private static TestDataFactory.SingleRequestMock badOAuthTokenMock() {
        TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
                403,
                'Forbidden',
                'Bad_OAuth_Token'
        );
        return singleRequestMock;
    }

    private static TestDataFactory.SingleRequestMock invalidGrantMock() {
        TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
                400,
                'Bad Request',
                'invalid_grant'
        );
        return singleRequestMock;
    }

    private static String getPlatformEventConfigMockURL() {
        String triggerId = AdminService.platformEventSubscriberTriggerId;
        String query = new QBuilder('PlatformEventSubscriberConfig')
            .selectFields(new Set<String>{'Id','UserId', 'PlatformEventConsumerId', 'DeveloperName', 'MasterLabel','BatchSize'})
            .add(QBuilder.condition('DeveloperName').equalsTo(AdminService.PLATFORM_EVENT_SUBSCRIBER_CONFIG_NAME))
            .add(QBuilder.condition('PlatformEventConsumerId').equalsTo(triggerId))
            .addLimit(1)
            .build();
        return System.Url.getOrgDomainUrl().toExternalForm() + ConfigUtil.TOOLING_QUERY_API_ENDPOINT + EncodingUtil.urlEncode(query, 'UTF-8');
    }

    private static TestDataFactory.SingleRequestMock getPlatformEventConfigMock() {
        TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
            200,
            'OK',
            JSON.serialize(new Map<String, Object>{
                ConfigUtil.TOOLING_ITEMS_KEY_RECORDS => new List<Map<String, Object>>{
                    new Map<String, Object>{'Id'=>'platformEventId'}
                }
            })
        );
        return singleRequestMock;
    }

    public class YourWebServiceMockImpl implements WebServiceMock {
        private MetadataService.CaseSettings[] records;

        public YourWebServiceMockImpl(MetadataService.CaseSettings[] records) {
            this.records = records;
        }
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {

            MetadataService.readCaseSettingsResponse_element metadataResponse = new MetadataService.readCaseSettingsResponse_element();
            MetadataService.ReadCaseSettingsResult result = new MetadataService.ReadCaseSettingsResult();
            result.records = this.records;
            metadataResponse.result = result;

            response.put('response_x', metadataResponse);
        }
    }

}