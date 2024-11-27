@isTest
public class Test_StackTraceParser {

    @IsTest
    private static void testFlowWaitParser() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);

        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(Test_LogService.getTestStub('FLOW_WAIT_ALL_TYPES_METADATA')));
        String stacktrace = String.valueOf(Test_LogService.getTestStub('FLOW_WAIT_ALL_TYPES_STACKTRACE')).replaceAll('00D6g000005kAqN', Test_LogService.CONNECETED_ORG_NAME);
        FlowService.Flow flow = FlowService.parseFlowStackTrace(stacktrace);
        System.assertNotEquals(null, flow);
        System.assertNotEquals(null, flow.elements);
        System.assertNotEquals(null, flow.edges);

        Map<String, FlowService.FlowElement> elements = flow.elements;
        FlowService.FlowElement waitDecision = elements.get('wait11');
        System.assertNotEquals(null, waitDecision);
        System.assertEquals(true, waitDecision.executed);
        Map<String, Object> metadataInfoWaitDecision = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(waitDecision.metadataInfo));
        System.assertEquals(true, metadataInfoWaitDecision.containsKey('elementSubtype'));
        System.assertEquals(true, metadataInfoWaitDecision.containsKey('events'));

        FlowService.FlowElement waitDuration = elements.get('wait22');
        System.assertNotEquals(null, waitDuration);
        System.assertEquals(true, waitDuration.executed);
        Map<String, Object> metadataInfoWaitDuration = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(waitDuration.metadataInfo));
        System.assertEquals(true, metadataInfoWaitDuration.containsKey('elementSubtype'));
        System.assertEquals('WaitDuration', String.valueOf(metadataInfoWaitDuration.get('elementSubtype')));
        System.assertEquals(true, metadataInfoWaitDuration.containsKey('events'));
        List<Object> events = (List<Object>)metadataInfoWaitDuration.get('events');
        Map<String, Object> eventDuration = (Map<String, Object>)events.get(0);
        System.assertEquals(true, eventDuration.containsKey('offset'));
        System.assertEquals(true, eventDuration.containsKey('offsetUnit'));

        FlowService.FlowElement waitDate = elements.get('wait33');
        System.assertNotEquals(null, waitDate);
        System.assertEquals(false, waitDate.executed);
        Map<String, Object> metadataInfoWaitDate = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(waitDate.metadataInfo));
        System.assertEquals(true, metadataInfoWaitDate.containsKey('elementSubtype'));
        System.assertEquals('WaitDate', String.valueOf(metadataInfoWaitDate.get('elementSubtype')));
        System.assertEquals(true, metadataInfoWaitDate.containsKey('events'));
        events = (List<Object>)metadataInfoWaitDate.get('events');
        Map<String, Object> eventDate = (Map<String, Object>)events.get(0);
        System.assertEquals(true, eventDate.containsKey('resumeDate'));
        System.assertEquals(true, eventDate.containsKey('resumeDate'));


        Test.stopTest();
    }

    @IsTest
    private static void test_parse_flow_multi_subflows() {
        
        String testStub = String.valueOf(Test_LogService.getTestStub('FLOW_MULTI_SUBFLOWS_STACKTRACE'));
        
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStub);
        FlowService.FlowErrorAbbreviateResult abbreviatedTestStub = sp.abbreviateStacktraceErrorMessages();
        
        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertEquals(true, !stackTraceInfo.stacktraceElementsMap.isEmpty());
        System.assertEquals(3, stackTraceInfo.stacktraceElementsMap.keySet().size());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);
    }

    @IsTest
    static void test_handle_flow_error_with_subflows() {

        Test_LogService.initSettings();
        
        //ErrorEmailHandler
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        List<string> emails = new List<string>{'testemail1@gmail.com','testemail1@gmail.com'};
        
        email.subject = 'An error occurred with your "GovnopaketFlowContact1" flow';
        email.fromAddress = 'system@salesforce.com';
        email.toAddresses = emails;
        email.htmlBody = String.valueOf(Test_LogService.getTestStub('FLOW_MULTI_SUBFLOWS_STACKTRACE')).replaceAll('00D6g000005kAqN', Test_LogService.CONNECETED_ORG_NAME);

        Messaging.InboundEmail.Header dateHeader = new Messaging.InboundEmail.Header();
        dateHeader.name = 'Date';
        dateHeader.value = '01 Jun 2023 14:31:46 -0700';
        email.headers = new List<Messaging.InboundEmail.Header>{dateHeader};

        Test.startTest();
        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(Test_LogService.getTestStub('FLOW_MULTI_SUBFLOWS_METADATA')));

        ErrorEmailHandler testInbound = new ErrorEmailHandler();
        testInbound.handleInboundEmail(email, env);
        Test.stopTest();

        Log__c failedFlowLog = [SELECT Id, Stacktrace_Parse_Result__c, Post_Processing_Status__c FROM Log__c WHERE Category__c = 'Flow' LIMIT 1];
        System.assertNotEquals(null, failedFlowLog.Stacktrace_Parse_Result__c);
    }

    @IsTest
    private static void test_abbreviate_bulk_flow_multi_entry_without_error_details() {
        
        String testStub = String.valueOf(Test_LogService.getTestStub('TEST_FLOW_BULK_ERROR_STACKTRACE1'));
        
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStub);
        FlowService.FlowErrorAbbreviateResult abbreviatedTestStub = sp.abbreviateStacktraceErrorMessages();
        System.assertNotEquals(null, abbreviatedTestStub.abbreviatedStacktrace);
        System.assertEquals(true, testStub.length() > abbreviatedTestStub.abbreviatedStacktrace.length());

        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);
    }

    @IsTest
    private static void test_abbreviate_bulk_flow_multi_entry_with_error_details() {
        
        String testStub = String.valueOf(Test_LogService.getTestStub('TEST_FLOW_BULK_ERROR_STACKTRACE2'));
        
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStub);
        FlowService.FlowErrorAbbreviateResult abbreviatedTestStub = sp.abbreviateStacktraceErrorMessages();
        System.assertNotEquals(null, abbreviatedTestStub.abbreviatedStacktrace);
        System.assertEquals(true, testStub.length() > abbreviatedTestStub.abbreviatedStacktrace.length());

        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);
    }


    @IsTest
    private static void test_abbreviate_large_flow_multi_entry() {
        String testStub = [SELECT Body FROM StaticResource WHERE Name = 'FlowParserLargeMultiFlowEntry'].Body.toString();
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStub);
        FlowService.FlowErrorAbbreviateResult abbreviatedTestStub = sp.abbreviateStacktraceErrorMessages();
        System.assertNotEquals(null, abbreviatedTestStub.abbreviatedStacktrace);
        System.assertEquals(true, testStub.length() > abbreviatedTestStub.abbreviatedStacktrace.length());

        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);
    }

    @IsTest
    private static void test_abbreviate_large_flow_entry() {
        String testStub = [SELECT Body FROM StaticResource WHERE Name = 'FlowParserLargeFlowEntry'].Body.toString();
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStub);
        FlowService.FlowErrorAbbreviateResult abbreviatedTestStub = sp.abbreviateStacktraceErrorMessages();
        System.assertNotEquals(null, abbreviatedTestStub.abbreviatedStacktrace);
        System.assertEquals(true, testStub.length() > abbreviatedTestStub.abbreviatedStacktrace.length());

        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);
    }

    @IsTest
    private static void test_abbreviate_large_error_message() {
        String testStub = [SELECT Body FROM StaticResource WHERE Name = 'FlowParserLargeErrorMessage'].Body.toString();
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStub);
        FlowService.FlowErrorAbbreviateResult abbreviatedTestStub = sp.abbreviateStacktraceErrorMessages();
        System.assertNotEquals(null, abbreviatedTestStub.abbreviatedStacktrace);
        System.assertEquals(true, testStub.length() > abbreviatedTestStub.abbreviatedStacktrace.length());

        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);
    }

    public static String stackTrace1 = '' +
    'Class.System.JSON.deserialize: line 15, column 1\n' +
    'Class.StackTraceParser.getClassesMap: line 39, column 1\n' +
    'AnonymousBlock: line 42, column 1\n' +
    'AnonymousBlock: line 42, column 1';

    public static String stackTrace2 = '' +
    'Class.SBQQ.QuoteService: line 336, column 1\n' +
    'Class.SBQQ.QuoteService: line 273, column 1\n' +
    'Class.SBQQ.QuoteService: line 269, column 1\n' +
    'Class.SBQQ.QuoteService: line 216, column 1\n' +
    'Class.SBQQ.QueueableCalculatorService.CalculateSyncher: line 242, column 1\n' +
    'Class.SBQQ.QueueableCalculatorService.execute: line 58, column 1';

    public static String stackTrace3 = '' +
    'Class.SBQQ.RestClient.send: line 77, column 1\n' +
    'Class.SBQQ.RestClient.post: line 43, column 1\n' +
    'Class.SBQQ.JSQCClient.calculate: line 72, column 1\n' +
    'Class.SBQQ.QuoteService.calculate: line 303, column 1\n' +
    'Class.SBQQ.QuoteService.calculate: line 273, column 1\n' +
    'Class.SBQQ.QuoteService.calculate: line 269, column 1\n' +
    'Class.SBQQ.QuoteService.calculateAndSynch: line 216, column 1\n' +
    'Class.SBQQ.QuoteService.calculateAndSynch: line 222, column 1\n' +
    'Trigger.SBQQ.QuoteAfter: line 45, column 1';

    public static String stackTrace4 = '' +
    'Trigger.LoggerTest1.LogTrigger: line 3, column 1';


    static testMethod void test1 () {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.ApexClassesResponseWrapper resp = new StackTraceParser.ApexClassesResponseWrapper();
        resp.size = 1;
        resp.records = new List<StackTraceParser.ApexClassWrapper>();
        StackTraceParser.ApexClassWrapper c1 = new StackTraceParser.ApexClassWrapper();
        c1.Id = 'Id';
        c1.Name = 'TestClass';
        c1.Body = 'test class body here ...';
        resp.records.add(c1);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(JSON.serialize(resp), 200));

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById('00D40000000N3x2');

        System.assertNotEquals(StackTraceParser.corg, null);

        List<StackTraceParser.StackTraceParseResult> result = StackTraceParser.parseStackTrace(stackTrace1);

        System.assertEquals(4, result.size());

        Test.stopTest();

    }

    static testMethod void test2 () {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.ApexClassesResponseWrapper resp = new StackTraceParser.ApexClassesResponseWrapper();
        resp.size = 1;
        resp.records = new List<StackTraceParser.ApexClassWrapper>();
        StackTraceParser.ApexClassWrapper c1 = new StackTraceParser.ApexClassWrapper();
        c1.Id = 'Id';
        c1.Name = 'TestClass';
        c1.Body = 'test class body here ...';
        resp.records.add(c1);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(JSON.serialize(resp), 200));

        Log__c log = new Log__c(
            Details__c = stackTrace3,
            Stacktrace__c = stackTrace3
        );
        insert log;

        Test.stopTest();

        System.assertNotEquals(null, log.Stacktrace__c);
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {

        public Integer testResponseCode = 200;
        public String testResponse = null;

        public MockHttpResponseGenerator(String testResponse, Integer testResponseCode) {
            this.testResponse = testResponse;
            this.testResponseCode = testResponseCode;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.testResponse);
            res.setStatusCode(this.testResponseCode);
            return res;
        }
    }

    public class YourWebServiceMockImpl implements WebServiceMock {
        private String jsonData;

        public YourWebServiceMockImpl(String jsonData) {
            this.jsonData = jsonData;
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

            MetadataService.readFlowResponse_element metadataResponse = new MetadataService.readFlowResponse_element();
            MetadataService.ReadFlowResult result = (MetadataService.ReadFlowResult)JSON.deserialize(this.jsonData, MetadataService.ReadFlowResult.class);
            metadataResponse.result = result;

            response.put('response_x', metadataResponse);
        }
    }

    @IsTest
    private static void testFlowParser() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);

        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(Test_LogService.getTestStub('flowJSON_all_actions')));
        FlowService.Flow flow = FlowService.parseFlowStackTrace(Test_LogService.getTestStub('flow_AllActions_StackTrace'));
        System.assertNotEquals(null, flow);
        System.assertNotEquals(null, flow.elements);
        System.assertNotEquals(null, flow.edges);

        Test.stopTest();
    }

    @IsTest
    private static void testProcessBuilderParser() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(Test_LogService.getTestStub('processBuilderJSON_ResponseNameGroupCall'), 200));
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(Test_LogService.getTestStub('processBuilderJSON_all_actions')));
        FlowService.ProcessBuilder processBuilder = FlowService.parseProcessBuilderStackTrace(Test_LogService.getTestStub('processBuilder_AllActions_StackTrace'));
        System.assertNotEquals(null, processBuilder);
        System.assertNotEquals(null, processBuilder.decisions);
        System.assertEquals(3, processBuilder.decisions.size());

        System.assertEquals(3, processBuilder.start.sections.size());
        System.assertEquals(FlowService.SideBarItemType.TEXT, processBuilder.start.sections.get(0).itemType);
        System.assertEquals(FlowService.SideBarItemType.RADIOBUTTON, processBuilder.start.sections.get(1).itemType);
        System.assertEquals(FlowService.SideBarItemType.CHECKBOX, processBuilder.start.sections.get(2).itemType);

        System.assertEquals('Account', processBuilder.start.sections.get(0).value);
        System.assertEquals(FlowService.PB_LABEL_OBJECT, processBuilder.start.sections.get(0).label);
        

        // start sidebar info
        for(FlowService.SideBarSection sbs : processBuilder.start.sections) {
            System.assertNotEquals(null, sbs.itemType);
            System.assertNotEquals(null, sbs.label);
        }

        // decisions info
        for(FlowService.ProcessBuilderDecision pbd : processBuilder.decisions) {

            System.assertNotEquals(null, pbd.label);
            System.assertNotEquals(null, pbd.name);
            System.assertNotEquals(null, pbd.executed);
            System.assertNotEquals(null, pbd.index);

            // decisions sidebar info
            for(FlowService.SideBarSection sbs : pbd.sections) {
                System.assertNotEquals(null, sbs.itemType);
                System.assertNotEquals(null, sbs.label);
            }

            // decisions actions info
            for(List<FlowService.ProcessBuilderAction> pbaList : pbd.actions) {

                for(FlowService.ProcessBuilderAction pba : pbaList) {
                    System.assertNotEquals(null, pba.name);
                    System.assertNotEquals(null, pba.label);
                    System.assertNotEquals(null, pba.actionType);
                    System.assertNotEquals(null, pba.executed);

                    // decisions actions sidebar info
                    for(FlowService.SideBarSection sbs : pba.sections) {
                        System.assertNotEquals(null, sbs.itemType);
                        System.assertNotEquals(null, sbs.label);
                    }
                }
            }
        }

        Test.stopTest();
    }

    @IsTest
    private static void testTruncateAuditTrailItems() {
        List<Object> testItems = new List<Object>();
        for(Integer i = 0; i<100; i++){
            testItems.add(new Map<String, Object>{'Name' => 'TestLine' + i});
        }
        Integer testItemsSize = JSON.serialize(testItems).length();
        Integer maxTestItemsSize = Integer.valueOf(testItemsSize * 0.91);

        List<Object> resultTestItems;
        Integer resultItemsSize;

        Test.startTest();
        resultTestItems = LogPostProcessingService.truncateItems(maxTestItemsSize, testItems);
        resultItemsSize = JSON.serialize(resultTestItems).length();
        Test.stopTest();

        System.assertNotEquals(null, resultItemsSize);
        System.assertEquals(true, resultItemsSize < testItemsSize);
        System.assertEquals(true, resultItemsSize <= maxTestItemsSize);
        system.assertEquals(true, resultTestItems.size() < testItems.size());
    }

    @IsTest
    private static void testOrchestratorParser() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);
        
        String testStubMetadata = String.valueOf(Test_LogService.getTestStub('ORCHESTRATOR_FAILED_FLOW_METADATA'));
        String testStubStacktrace = String.valueOf(Test_LogService.getTestStub('ORCHESTRATOR_FAILED_FLOW_STACKTRACE'));
        
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(testStubMetadata));
        FlowService.Flow orchestratorFlow = FlowService.parseFlowStackTrace(testStubStacktrace);
        System.assertNotEquals(null, orchestratorFlow);
        System.assertNotEquals(null, orchestratorFlow.elements);
        System.assertNotEquals(null, orchestratorFlow.edges);
    }

    @IsTest
    private static void testOrchestratorFailedFlowParser() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);
        String testStubMetadata = String.valueOf(Test_LogService.getTestStub('ORCHESTRATOR_FLOW_METADATA'));
        String testStubStacktrace = String.valueOf(Test_LogService.getTestStub('ORCHESTRATOR_STACK_TRACE'));
        
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(testStubMetadata));
        FlowService.Flow orchestratorFlow = FlowService.parseFlowStackTrace(testStubStacktrace);
        System.assertNotEquals(null, orchestratorFlow);
        System.assertNotEquals(null, orchestratorFlow.elements);
        System.assertNotEquals(null, orchestratorFlow.edges);
        System.assertNotEquals(null, orchestratorFlow.orchestratorFailedFlowApiName);
    }

    @IsTest
    private static void testFlowWithSameLabelsParser() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);
        String testStubMetadata = String.valueOf(Test_LogService.getTestStub('FLOW_SAME_API_LABELS_METADATA'));
        String testStubStacktrace = String.valueOf(Test_LogService.getTestStub('FLOW_SAME_API_LABELS_ELEMENTS_STACKTRACE'));
        
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(testStubMetadata));
        FlowService.Flow testedFlow = FlowService.parseFlowStackTrace(testStubStacktrace);
        System.assertNotEquals(null, testedFlow);
        System.assertNotEquals(null, testedFlow.elements);
        System.assertNotEquals(null, testedFlow.edges);
        for(FlowService.FlowElement stElement : testedFlow.elements.values()) {
            System.assertEquals(true, stElement.executed);
        }
    }

    @IsTest
    private static void testFlowParserFromManagedPackage() {

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);
        String testStubMetadata = String.valueOf(Test_LogService.getTestStub('FLOW_MANAGED_PACKAGE_STACKTRACE_METADATA'));
        String testStubStacktrace = String.valueOf(Test_LogService.getTestStub('FLOW_MANAGED_PACKAGE_STACKTRACE'));
        
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(testStubMetadata));

        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStubStacktrace);
        FlowService.FlowErrorAbbreviateResult abbreviatedHtmlBody = sp.abbreviateStacktraceErrorMessages();
        Log__c log = LogService.createLogFromEmailBody(testStubStacktrace, 'An error occurred with your "GovnopaketFlowContact1" flow', 'test@test.com', Datetime.now());
        DatabaseUtils.getInstance().performInsertDML(new List<Log__c>{log}, Schema.SObjectType.Log__c)
            .handleError(LogService.class.getName(), '.', null);
        Test.stopTest();

        log = [SELECT Salesforce_Error_Id__c, Flow_API_Name__c, Flow_Version__c, Area__c, Type__c , Hash_1__c, Stacktrace_Parse_Result__c FROM Log__c WHERE Id = :log.Id LIMIT 1];
        system.assertEquals('testgovnopaket1__GovnopaketFlowContact1', log.Flow_API_Name__c);
        system.assertEquals('1', log.Flow_Version__c);
        system.assertEquals('Flow', log.Area__c);
        system.assertEquals('Autolaunched Flow', log.Type__c);
        system.assertNotEquals(null, log.Hash_1__c);
        system.assertNotEquals(null, log.Stacktrace_Parse_Result__c);
    }

    @IsTest
    private static void testFlowParserFromConvertedProcessBuilder() {

        String testStub = String.valueOf(Test_LogService.getTestStub('flowConvertedFromProcessBuilderMetadata'));
        String testStubStacktrace = String.valueOf(Test_LogService.getTestStub('FLOW_CONVERTED_FROM_PROCESS_BUILDER_STACKTRACE'));
    
        FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(testStubStacktrace);
        
        FlowService.FlowStacktraceInfo stackTraceInfo = sp.parse();
        System.assertNotEquals(null, stackTraceInfo);
        System.assertNotEquals(null, stackTraceInfo.stacktraceElements);
        System.assertEquals(true, !stackTraceInfo.stacktraceElements.isEmpty());
        System.assertEquals(2, stackTraceInfo.stacktraceElements.size());
        System.assertNotEquals(null, stackTraceInfo.errorMessage);
        System.assertNotEquals(null, stackTraceInfo.errorMessageHtml);
        System.assertNotEquals(null, stackTraceInfo.flowDetails);
        System.assertNotEquals(null, stackTraceInfo.flowInterviewDetails);
        System.assertNotEquals(null, stackTraceInfo.howTheInterviewStarted);
        System.assertNotEquals(null, stackTraceInfo.salesforceErrorId);

        Test_LogService.initSettings();

        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);

        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(testStub));

        Log__c log = LogService.createLogFromEmailBody(testStubStacktrace, 'An error occurred with your "GovnopaketFlowContact1" flow', 'test@test.com', Datetime.now());
        DatabaseUtils.getInstance().performInsertDML(new List<Log__c>{log}, Schema.SObjectType.Log__c)
            .handleError(LogService.class.getName(), '.', null);
        Test.stopTest();

        log = [SELECT Salesforce_Error_Id__c, Flow_API_Name__c, Flow_Version__c, Area__c, Type__c , Hash_1__c, Stacktrace_Parse_Result__c FROM Log__c WHERE Id = :log.Id LIMIT 1];
        system.assertEquals('IO_Line_Item_Clone_Flow', log.Flow_API_Name__c);
        system.assertEquals('3', log.Flow_Version__c);
        system.assertEquals('Flow', log.Area__c);
        system.assertEquals('Autolaunched Flow', log.Type__c);
        system.assertNotEquals(null, log.Hash_1__c);
        system.assertNotEquals(null, log.Stacktrace_Parse_Result__c);
    }

    @IsTest
    static void test_parse_bulk_flow_errors_to_unic_logs() {
        //ErrorEmailHandler
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        List<string> emails = new List<string>{'testemail1@gmail.com','testemail1@gmail.com'};
        
        email.subject = 'An error occurred with your "FailedContactAccounts" flow';
        email.fromAddress = 'system@salesforce.com';
        email.toAddresses = emails;

        Messaging.InboundEmail.Header dateHeader = new Messaging.InboundEmail.Header();
        dateHeader.name = 'Date';
        dateHeader.value = '01 Jun 2023 14:31:46 -0700';
        email.headers = new List<Messaging.InboundEmail.Header>{dateHeader};

        String testStacktraceStub = String.valueOf(Test_LogService.getTestStub('flowToAbbreviateBulkFlowStacktrace'));
        testStacktraceStub = testStacktraceStub.replace('00D6g000005kAqN', Test_LogService.CONNECETED_ORG_NAME);
        email.htmlBody = testStacktraceStub;

        Test_LogService.initSettings();
        
        Test.startTest();

        StackTraceParser.corg = ConnectedOrgService.getConnectedOrgById(Test_LogService.CONNECETED_ORG_NAME);
        String metadataResponse = String.valueOf(Test_LogService.getTestStub('FLOW_BULK_STACKTRACE_TO_ABBREVIATE_METADATA'));
        Test.setMock(WebServiceMock.class, new YourWebServiceMockImpl(metadataResponse));
            
        ErrorEmailHandler testInbound = new ErrorEmailHandler();
        testInbound.handleInboundEmail(email, env);
        Test.stopTest();

        List<Log__c> failedFlowLogs = [SELECT Id, Summary__c, Hash_1__c FROM Log__c WHERE Category__c = 'Flow' LIMIT 2];
        System.assertEquals(2, failedFlowLogs.size());
        system.assertNotEquals(failedFlowLogs.get(0).Summary__c, failedFlowLogs.get(1).Summary__c);
        system.assertNotEquals(failedFlowLogs.get(0).Hash_1__c, failedFlowLogs.get(1).Hash_1__c);
    }
}