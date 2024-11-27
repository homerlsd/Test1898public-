public with sharing class OpenAI {

	public static String doChat(Issue__c issue) {
		String result;
		try {
			String response = query(generatePrompt(issue));
			Response chatResponse = (Response)JSON.deserialize(response, Response.class);
			if (chatResponse.choices != null && chatResponse.choices.size() > 0){
				result = chatResponse.choices[0].message?.content;
			}
		} catch (Exception e) {
			Logger.getInstance().internalError(e, issue.Id, false, null, 'OpenAIController.doChat');
			throw e;
		}
		return result;
	}
    
    private static final Integer MAX_TOKENS_OPENAI = 1000;

    public static String query(String prompt) {
		Map<String,Object> body = new Map<String,Object> {
				'model' => 'gpt-4o-mini',
				'messages' => new List<Map<String, Object>>{
					new Map<String, Object>{
						'role' => 'system',
						'content' => 'You are an experienced Salesforce Technical Professional. Help me with the following:'
					},
					new Map<String, Object>{
						'role' => 'user',
						'content' => prompt
					}
				},
				'temperature' => 1.0,
                'max_tokens' => MAX_TOKENS_OPENAI,
				'response_format' => new Map<String, Object>{'type' => 'json_object'}
		};
		return HttpUtils.post(
				ConfigUtil.OPEN_AI_COMPLETIONS_ENDPOINT,
				JSON.serialize(body),
				ConfigUtil.OPEN_AI_HEADERS,
				200
		);
	}

	public static Boolean validateToken(String token) {
		Map<String, String> headers = new Map<String, String>{
				'Content-Type' => 'application/json',
				'Authorization' => 'Bearer ' + token
		};
		try {
			String response = HttpUtils.get(
					ConfigUtil.OPEN_AI_USAGE_ENDPOINT,
					headers,
					401
			);
			return !response.contains('Incorrect API key');
		} catch (HttpUtils.HttpUtilsException e) {
			return true;
		}
	}

	//max character count for error message
	private static final Integer MAX_ERROR_LENGTH = 7500;

	private static String generatePrompt(Issue__c issue) {
		String prompt = 'The information about a salesforce issue is delimited by triple backticks below,\n';
		prompt += 'Analyze the error and occurrence information and provide response in JSON format with keys and values encolsed in double quotes and with the following properties: \n';
		prompt += 'RootCauseAnalysis - The root cause analysis of the error;';
		prompt += 'ResolutionOptions - an array of resolution options;';
		prompt += 'SeverityEstimate - severity estimate as one of these values: Low, Medium, High, Highest;';
		prompt += 'Justification - justification of the severity estimate;\n';
		prompt += 'To produce a severity estimate take into account how long the issue has been happening, how many users and data were impacted as well as the issue occurrence frequency.\n';
		prompt += 'The longer it has been since the issue last occurred the lower the severity of the issue. Generally, if the issue has not occurred for more than 30 days, it at most a low severity.\n';

		String errorDetails = issue.Log__r.Details__c?.abbreviate(MAX_ERROR_LENGTH);
		prompt += '```' + errorDetails + '\n';

		if (String.isNotBlank(issue.Log__r.Flow_API_Name__c)) {
			prompt += 'Flow API Name: ' + issue.Log__r.Flow_API_Name__c + '\n';
			prompt += 'Flow Type: ' + issue.Log__r.Type__c + '\n';
			prompt += 'Flow Version: ' + issue.Log__r.Flow_Version__c + '\n';
		}

		prompt += 'Issue Number: ' + issue.Name + ' \n';

		Integer first = Math.max(1, System.today().daysBetween(Date.valueOf(issue.First_Occurred_On__c)));
		Integer last = Math.max(1, System.today().daysBetween(Date.valueOf(issue.Last_Occurred_On__c)));
		Integer totalDays = Math.max(1, Date.valueOf(issue.First_Occurred_On__c).daysBetween(Date.valueOf(issue.Last_Occurred_On__c)));

		prompt += 'Issue Last Occurred ' + last + ' days ago\n';
		prompt += 'Issue First Occurred ' + first + ' days ago\n';
		prompt += 'Issue has been occurring for a total of: ' +  totalDays + ' days\n';
		prompt += 'Number of impacted data records: ' + issue.Impacted_Objects_Count__c + '\n';
		prompt += 'Number of impacted users: ' + issue.Impacted_Users_Count__c + '\n';
		prompt += 'Average days between error occurrences: ' + Math.round(issue.Average_Frequency__c != null ? issue.Average_Frequency__c : 0) + '\n';

		prompt += 'Category: ' + issue.Category__c + '\n';
		prompt += 'Functional Area: ' + issue.Functional_Area__c + '\n```';

		return prompt;
	}

	public class Response {
		public List<Choice> choices;
	}

	public class Choice {
		public Message message;
	}

	public class Message {
		public String content;
	}

}