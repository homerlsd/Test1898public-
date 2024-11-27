@IsTest
private class SystemOverviewControllerTest {

	@TestSetup
	private static void testSetup() {
		TestDataFactory.createConnectedOrg();
	}

	@IsTest
	private static void test_getOrgInfo() {
		Test.startTest();
		Organization org = SystemOverviewController.getOrgInfo();
		Test.stopTest();
		System.assertNotEquals(null, org);
	}

	@IsTest
	private static void test_getUsersInfo() {
		Test.startTest();
		SystemOverviewController.UsersInfo usersInfo = SystemOverviewController.getUsersInfo();
		Test.stopTest();
		System.assertNotEquals(null, usersInfo);
		System.assertNotEquals(null, usersInfo.numberOfActiveUsers);
		System.assertNotEquals(null, usersInfo.numberOfActiveUsersForLast30Days);
		System.assertNotEquals(null, usersInfo.numberOfUsers);
		System.assertNotEquals(null, usersInfo.numberOfInactiveUsers);
	}

	@IsTest
	private static void test_getSystemOrgLimits() {
		Test.startTest();
		List<SystemOverviewController.SystemOrgLimit> systemOrgLimits = SystemOverviewController.getSystemOrgLimits();
		Test.stopTest();
		System.assertNotEquals(null, systemOrgLimits);
	}

	@IsTest
	private static void test_getCodeInfo() {
		Test.startTest();
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
		String queryLWC = String.format(SystemOverviewController.CODE_INFO_QUERY, new List<String>{'LightningComponentBundle'});
		endpoint2TestResp.put('https://test_Instance_Url' + ConfigUtil.TOOLING_QUERY_API_ENDPOINT + EncodingUtil.urlEncode(queryLWC, 'UTF-8'), getLightningComponentBundle());
		String queryFlow = String.format(SystemOverviewController.CODE_INFO_QUERY, new List<String>{'FlowDefinition'});
		endpoint2TestResp.put('https://test_Instance_Url' + ConfigUtil.TOOLING_QUERY_API_ENDPOINT + EncodingUtil.urlEncode(queryFlow, 'UTF-8'), getFlowDefinition());
		HttpCalloutMock multiCalloutMock = new TestDataFactory.MultiRequestMock(endpoint2TestResp);
		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
		List<SystemOverviewController.CodeInfo> lstCodeInfo = SystemOverviewController.getCodeInfo();
		Test.stopTest();
		System.assertNotEquals(null, lstCodeInfo);
	}

	@IsTest
	private static void test_getCodeInfoDetails() {
		Test.startTest();
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
		String queryLWC = String.format(SystemOverviewController.CODE_INFO_DETAILS_LIGHTNING_QUERY, new List<String>{'LightningComponentBundle'});
		endpoint2TestResp.put('https://test_Instance_Url' + ConfigUtil.TOOLING_QUERY_API_ENDPOINT + EncodingUtil.urlEncode(queryLWC, 'UTF-8'), getLightningComponentBundleDetails());
		String queryFlow = SystemOverviewController.CODE_INFO_DETAILS_FLOW_QUERY;
		endpoint2TestResp.put('https://test_Instance_Url' + ConfigUtil.TOOLING_QUERY_API_ENDPOINT + EncodingUtil.urlEncode(queryFlow, 'UTF-8'), getFlowDefinitionDetails());
		HttpCalloutMock multiCalloutMock = new TestDataFactory.MultiRequestMock(endpoint2TestResp);
		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
		for (String objectName : SystemOverviewController.CODE_INFO_OBJECTS_MAP.keySet()) {
			List<SystemOverviewController.CodeInfoDetail> codeInfoDetails = SystemOverviewController.getCodeInfoDetails(objectName);
			System.assertNotEquals(null, codeInfoDetails);
		}
		Test.stopTest();
	}

	private static TestDataFactory.SingleRequestMock getLightningComponentBundle() {
		TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
				200,
				'OK',
				'{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"AggregateResult","records":[{"attributes":{"type":"AggregateResult"},"count_id":5,"namespacePrefix":"test"}]}'
		);
		return singleRequestMock;
	}

	private static TestDataFactory.SingleRequestMock getLightningComponentBundleDetails() {
		TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
				200,
				'OK',
				'{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"LightningComponentBundle","records":[{"attributes":{"type":"LightningComponentBundle","url":"/services/data/v56.0/tooling/sobjects/LightningComponentBundle/0Rb5x000001PpppXXX"},"MasterLabel":"test","ApiVersion":56.0,"NamespacePrefix":"test"}]}'
		);
		return singleRequestMock;
	}

	private static TestDataFactory.SingleRequestMock getFlowDefinition() {
		TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
				200,
				'OK',
				'{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"AggregateResult","records":[{"attributes":{"type":"AggregateResult"},"count_id":10,"namespacePrefix":"test"}]}'
		);
		return singleRequestMock;
	}

	private static TestDataFactory.SingleRequestMock getFlowDefinitionDetails() {
		TestDataFactory.SingleRequestMock singleRequestMock = new TestDataFactory.SingleRequestMock(
				200,
				'OK',
				'{"size":15,"totalSize":15,"done":true,"queryLocator":null,"entityTypeName":"AggregateResult","records":[{"attributes":{"type":"AggregateResult","url":"/services/data/v56.0/tooling/sobjects/AggregateResult/3005e000001Pp7FXXX"},"MasterLabel":"test","ApiVersion":56.0,"Id":"3005e000001Pp7FXXX","NamespacePrefix":"test"}]}'
		);
		return singleRequestMock;
	}

}