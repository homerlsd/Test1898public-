public with sharing class FlowService {

	public static final String HTML_TAG_HORIZONTAL_RULE_OPEN = '<hr>';
	public static final String HTML_TAG_BREAK_OPEN = '<br>';
	public static final String HTML_TAG_PARAGRAPH_OPEN = '<p>';
	public static final String HTML_TAG_PARAGRAPH_CLOSE = '</p>';
	public static final String HTML_TAG_BACKSLASH = '\n';
	public static final String PB_CURRENT_SUPPORTED_API_VERSION = '54.0';
	public static final String FLOW_TYPE_ORCHESTRATOR = 'Flow Orchestration';
	public static final String FLOW_TYPE_AUTOLAUNCHED_FLOW = 'Autolaunched Flow';
	public static final String FLOW_ERROR_MESSAGE_PART_OCCURRED = 'occurred: ';
	public static final String FLOW_ERROR_MESSAGE_SEPARATOR = '---';
	public static final Integer FLOW_ABBREVIATE_ERROR_MESSAGE_SIZE = 1000;

	public static final String FLOW_ERROR_DETAILS_PART_HTML = '<span style="font-weight:bold;">Flow Details</span><br>';
	public static final String FLOW_ERROR_FLOW_ERROR_DETAILS_PART_HTML = '<hr>\n'+
	'<br><span style="font-size:x-large;font-weight:bold">Flow Error Details</span><br><br>\n'+
	'<p>\n'+
	'<span style="font-weight:bold;">Flow Details</span><br>';

	public class FlowErrorAbbreviateResult {
		public Map<String, String> errorMessages;
		public String abbreviatedStacktrace;

		public FlowErrorAbbreviateResult(){}

		public void addErrorMessages(List<String> htmlErrorMessages) {
			if(this.errorMessages == null) {
				this.errorMessages = new Map<String, String>();
			}
			for(String htmlErrorMessage : htmlErrorMessages) {
				String message = htmlErrorMessage?.stripHtmlTags()?.trim();
				String keyMessage = FlowExceptionParser.getValueForHash(LogService.removeExtraErrorDetails(message));
				this.errorMessages.put(keyMessage, message);
			}
		}
	}

	public interface FlowStacktraceParserInterface {
		String getFirstLines(String htmlText);
		String getLineValue(String htmlText);
		String getLineValue(String htmlText, String separator);
		List<String> getNameAndId(String htmlText);
		List<String> getNameAndId(String htmlText, String separator);
		Boolean isValidStacktraceElement(String htmlText);
		FlowErrorAbbreviateResult abbreviateStacktraceErrorMessages();
		FlowStacktraceInfo parse();
		String getFlowDetailsToken();
		String getFlowElementErrorStarts();
		String getSingleErrorMessageHtml(String part);
	}

	public class FlowStacktraceParser {
		FlowStacktraceParserInterface impl;

		public FlowStacktraceParser(String data) {
			this.impl = new FlowStacktraceParserWinter24Impl(data);
		}

		public FlowErrorAbbreviateResult abbreviateStacktraceErrorMessages() {
			return this.impl.abbreviateStacktraceErrorMessages();
		}

		public FlowStacktraceInfo parse() {
			return this.impl.parse();
		}
	}

	public class FlowStacktraceParserWinter24Impl extends FlowStacktraceParserDefImpl {

		public FlowStacktraceParserWinter24Impl(String data) {
			super(data);
		}

		public override String getFlowDetailsToken() {
			return PB_ST_FLOW_ERROR_DETAILS;
		}

		public override String getLineValue(String htmlText, String separator) {
			return (htmlText?.indexOf(separator) != -1) ? htmlText?.stripHtmlTags()?.split(separator)?.get(1)?.trim() : null;
		}

		public override List<String> getNameAndId(String htmlText, String separator) {
			String name;
			String id;
			if((htmlText?.indexOf(separator) != -1)) {
				String fullNameAndId = htmlText?.stripHtmlTags()?.split(separator)?.get(1)?.trim();
				if((fullNameAndId?.indexOf('(') != -1)) {
					id = fullNameAndId?.split('\\(')?.get(1)?.left(15);
					name = fullNameAndId?.split('\\(')?.get(0)?.trim();
				}
			}
			return new List<String>{id, name};
		}

		public override String getFlowElementErrorStarts() {
			return 'An Error Occurred with';
		}

		public override String getSingleErrorMessageHtml(String part) {
			String singleErrorMessageHtml;
			
			FlowService.HTMLIterator errorMessageIterator = new FlowService.HTMLIterator(part, HTML_TAG_BREAK_OPEN);
			while (errorMessageIterator.hasNext()) {
				String errorMessageHtml = errorMessageIterator?.next();
				
				String firstLinesPart = getFirstLines(errorMessageHtml);
				if(String.isNotBlank(firstLinesPart) && firstLinesPart.startsWith(PB_ST_FLOW_ERROR_ELEMENT)) {
					// Example: Error element submit (FlowActionCall).
					if(firstLinesPart.startsWith('Error element ') && firstLinesPart.endsWith(').')) {
						String labelAndTypeErrorElement = errorMessageHtml?.stripHtmlTags()?.trim()?.removeStart('Error element ')?.removeEnd('.');
						String labelErrorElement = labelAndTypeErrorElement?.split(' ')?.get(0);
						String typeErrorElement = labelAndTypeErrorElement?.split(' ')?.get(1)?.removeStart('(')?.removeEnd(')');
						this.headErrorStacktraceElement = new FlowStacktraceElement(typeErrorElement, labelErrorElement);
						this.headErrorStacktraceElement.apiType = typeErrorElement;
					}
					errorMessageHtml = errorMessageIterator?.next();

					if(String.isNotBlank(errorMessageHtml) && errorMessageHtml.containsIgnoreCase(FLOW_ERROR_MESSAGE_SEPARATOR)) {
						List<String> parts = errorMessageHtml.split(FLOW_ERROR_MESSAGE_SEPARATOR);
						Integer lastElementIndex = parts?.size() != 0 ? parts?.size() - 1 : 0;
						singleErrorMessageHtml = parts.get(lastElementIndex);
					}
					else {
						singleErrorMessageHtml = errorMessageHtml;
					}
				}
			}
			
			return singleErrorMessageHtml;
		}
	}

	public abstract class FlowStacktraceParserDefImpl  implements FlowStacktraceParserInterface {
		private String data;
		private FlowStacktraceElement headErrorStacktraceElement;

		public FlowStacktraceParserDefImpl(String data) {
			this.data = data;
		}

		public abstract String getFlowDetailsToken();
		public abstract String getFlowElementErrorStarts();
		public abstract String getSingleErrorMessageHtml(String part);

		public virtual String getFirstLines(String htmlText) {
			return htmlText?.abbreviate(1000)?.stripHtmlTags()?.replaceAll(HTML_TAG_BACKSLASH, '')?.trim();
		}

		public virtual String getLineValue(String htmlText) {
			return getLineValue(htmlText, ':');
		}

		public virtual String getLineValue(String htmlText, String separator) {
			return (htmlText?.indexOf(separator) != -1) ? htmlText?.split(separator)?.get(1)?.stripHtmlTags()?.trim() : null;
		}

		public virtual List<String> getNameAndId(String htmlText) {
			return getNameAndId(htmlText, ':');
		}

		public virtual List<String> getNameAndId(String htmlText, String separator) {
			String name;
			String id;
			if((htmlText?.indexOf(separator) != -1)) {
				String fullNameAndId = htmlText?.split(separator)?.get(1)?.stripHtmlTags()?.trim();
				if((fullNameAndId?.indexOf('(') != -1)) {
					id = fullNameAndId?.split('\\(')?.get(1)?.left(15);
					name = fullNameAndId?.split('\\(')?.get(0)?.trim();
				}
			}
			return new List<String>{id, name};
		}

		public virtual Boolean isValidStacktraceElement(String htmlText) {
			return (htmlText?.indexOf(':') != -1) && htmlText?.stripHtmlTags()?.split(':')?.size() >= 2;
		}

		public virtual FlowErrorAbbreviateResult abbreviateStacktraceErrorMessages() {
			FlowErrorAbbreviateResult result = new FlowErrorAbbreviateResult();

			String start = '';
			String headErrorPart = '';
			String flowEntry = '';
			String errorOccuredPart = '';
			String transactionRolledBackPart = '';
			String salesforceErrorIdPart = '';
			
			FlowService.HTMLIterator partsIterator = new FlowService.HTMLIterator(data, FlowService.HTML_TAG_HORIZONTAL_RULE_OPEN);
			while (partsIterator.hasNext()) {
				String part = partsIterator.next();
				String firstLinesPart = getFirstLines(part);

				if(String.isBlank(start)) {
					start = part;
				}
				else if(String.isBlank(flowEntry) && String.isNotBlank(firstLinesPart) && (firstLinesPart.startsWith(PB_ST_FLOW_ERROR_DETAILS) || firstLinesPart.startsWith(PB_ST_FLOW_DETAILS))) {
					flowEntry = part;
				}
				else if(String.isNotBlank(firstLinesPart) && firstLinesPart.containsIgnoreCase(FlowService.FLOW_ERROR_MESSAGE_PART_OCCURRED)) {
					errorOccuredPart = part;
				}
				else if(String.isNotBlank(firstLinesPart) && firstLinesPart.startsWith(PB_ST_TRANSACTION_ROLLED_BACK)) {
					transactionRolledBackPart = part;
				}
				// last section with salesforce error id
				else if(String.isNotBlank(firstLinesPart) && firstLinesPart.startsWith(PB_ST_SALESFORCE_ERROR_ID)) {
					salesforceErrorIdPart = part;
				}

				// fix bulk html stacktrace without Flow Error Details part
				if(String.isNotBlank(start) && String.isNotBlank(flowEntry)) {
					if(start.contains(PB_ST_FLOW_DETAILS) && !start.contains(PB_ST_FLOW_ERROR_DETAILS)) {
						start = start.replace(FLOW_ERROR_DETAILS_PART_HTML, FLOW_ERROR_FLOW_ERROR_DETAILS_PART_HTML);
						flowEntry = ' ';
					}
				}
			}
			
			if(String.isNotBlank(start) && start.containsIgnoreCase(FLOW_ERROR_MESSAGE_SEPARATOR)) {
				String fixedStart = '';
				FlowService.HTMLIterator brIterator = new FlowService.HTMLIterator(start, FlowService.HTML_TAG_BREAK_OPEN);
				while (brIterator.hasNext()) {
					String brPart = brIterator?.next();
					String firstLinesbrPart = getFirstLines(brPart?.stripHtmlTags()?.trim());

					if(String.isNotBlank(firstLinesbrPart) && firstLinesbrPart.startsWith(FlowService.PB_ST_FLOW_ERROR_ELEMENT)) {
						fixedStart += brPart;
						brPart = brIterator?.next();
						List<String> parts = brPart.split(FLOW_ERROR_MESSAGE_SEPARATOR);
						result.addErrorMessages(parts);
						if(result.errorMessages.size() > 1) {
							fixedStart += String.join(result.errorMessages.values(), FLOW_ERROR_MESSAGE_SEPARATOR);
						}
						else {
							fixedStart += parts.get(0);
						}
					}
					else {
						fixedStart += brPart;
					}
				}
				if(String.isNotBlank(fixedStart)) {
					start = fixedStart;
				}
			}
			if(String.isNotBlank(errorOccuredPart) && errorOccuredPart.containsIgnoreCase(FLOW_ERROR_MESSAGE_SEPARATOR)) {
				String fixedErrorOccuredPart = '';
				List<String> parts = errorOccuredPart.split(FLOW_ERROR_MESSAGE_SEPARATOR);
				result.addErrorMessages(parts);
				errorOccuredPart = String.join(result.errorMessages.values(), FLOW_ERROR_MESSAGE_SEPARATOR);
			}
			result.abbreviatedStacktrace = start  + HTML_TAG_HORIZONTAL_RULE_OPEN + flowEntry + errorOccuredPart + transactionRolledBackPart + salesforceErrorIdPart;
			return result;
		}

		public virtual FlowStacktraceInfo parse() {
			FlowStacktraceInfo info = new FlowStacktraceInfo();

			FlowService.HTMLIterator partsIterator = new FlowService.HTMLIterator(this.data, HTML_TAG_HORIZONTAL_RULE_OPEN);
			while (partsIterator.hasNext()) {
				String part = partsIterator.next();
				String firstLinesPart = getFirstLines(part);
				String detailsToken = getFlowDetailsToken();
				if(!this.data?.containsIgnoreCase(detailsToken)) {
					detailsToken = PB_ST_FLOW_DETAILS;
				}
				if(firstLinesPart?.startsWith(detailsToken) || firstLinesPart?.startsWith(PB_ST_TRANSACTION_ERROR_HANDLED)) {
					FlowService.HTMLIterator stacktraceIterator = new FlowService.HTMLIterator(part,HTML_TAG_PARAGRAPH_CLOSE);
					while (stacktraceIterator.hasNext()) {
						String stacktracePart = stacktraceIterator.next();
						String firstLinesStacktracePart = getFirstLines(stacktracePart);

						if(firstLinesStacktracePart?.startsWith(detailsToken)) {
							FlowService.HTMLIterator flowDetailsIterator = new FlowService.HTMLIterator(stacktracePart, HTML_TAG_BREAK_OPEN);
							info.flowDetails = new FlowDetails();
							while (flowDetailsIterator.hasNext()) {
								String flowDetailsRow = flowDetailsIterator.next();
								String firstLinesFlowDetailsRow = getFirstLines(flowDetailsRow);

								if(firstLinesFlowDetailsRow?.startsWith(PB_ST_VAR_FLOW_API_NAME_LABEL)) {
									info.flowDetails.flowApiName = getLineValue(flowDetailsRow);
								}
								else if(firstLinesFlowDetailsRow?.startsWith(PB_ST_VAR_TYPE_LABEL)) {
									info.flowDetails.type = getLineValue(flowDetailsRow);
								}
								else if(firstLinesFlowDetailsRow?.startsWith(PB_ST_VAR_VERSION_LABEL)) {
									info.flowDetails.version = getLineValue(flowDetailsRow);
								}
								else if(firstLinesFlowDetailsRow?.startsWith(PB_ST_VAR_STATUS_LABEL)) {
									info.flowDetails.status = getLineValue(flowDetailsRow);
								}
								else if(firstLinesFlowDetailsRow?.startsWith(PB_ST_VAR_ORG_LABEL)) {
									List<String> orgNameAndId = getNameAndId(flowDetailsRow);
									info.flowDetails.orgId = orgNameAndId?.get(0);
									info.flowDetails.orgName = orgNameAndId?.get(1);
								}
							}
						}
						else if(firstLinesStacktracePart?.startsWith(PB_ST_FLOW_INTERVIEW_DETAILS)) {
							FlowService.HTMLIterator flowInterviewDetailsIterator = new FlowService.HTMLIterator(stacktracePart, HTML_TAG_BREAK_OPEN);
							info.flowInterviewDetails = new FlowInterviewDetails();
							while (flowInterviewDetailsIterator.hasNext()) {
								String flowInterviewDetailsRow = flowInterviewDetailsIterator.next();
								String firstLinesFlowInterviewDetailsRow = getFirstLines(flowInterviewDetailsRow);

								if(firstLinesFlowInterviewDetailsRow?.startsWith(PB_ST_FLOW_VAR_INTERVIEW_LABEL)) {
									info.flowInterviewDetails.interviewLabel = getLineValue(flowInterviewDetailsRow);
								}
								else if(firstLinesFlowInterviewDetailsRow?.startsWith(PB_ST_FLOW_VAR_INTERVIEW_GUID)) {
									info.flowInterviewDetails.interviewGUID = getLineValue(flowInterviewDetailsRow);
								}
								else if(firstLinesFlowInterviewDetailsRow?.startsWith(PB_ST_VAR_CURRENT_USER_LABEL)) {
									List<String> userNameAndId = getNameAndId(flowInterviewDetailsRow);
									info.flowInterviewDetails.currentUserId = userNameAndId?.get(0);
									info.flowInterviewDetails.currentUserName = userNameAndId?.get(1);
								}
								else if(firstLinesFlowInterviewDetailsRow?.startsWith(PB_ST_VAR_START_TIME_LABEL)) {
									info.flowInterviewDetails.startTime = getLineValue(flowInterviewDetailsRow);
								}
								else if(firstLinesFlowInterviewDetailsRow?.startsWith(PB_ST_VAR_DURATION_LABEL)) {
									info.flowInterviewDetails.duration = getLineValue(flowInterviewDetailsRow);
								}
							}
						}
						else if(firstLinesStacktracePart?.startsWith(PB_ST_HOW_START)) {
							FlowService.HTMLIterator howStartedIterator = new FlowService.HTMLIterator(stacktracePart, HTML_TAG_BREAK_OPEN);
							info.howTheInterviewStarted = new HowTheInterviewStarted();
							while (howStartedIterator.hasNext()) {
								String howStartedIteratorRow = howStartedIterator.next();
								String firstLinesHowStartedIteratorRow = getFirstLines(howStartedIteratorRow);

								if(firstLinesHowStartedIteratorRow.startsWith(PB_ST_VAR_RUN_API_LABEL)) {
									info.howTheInterviewStarted.apiVersion = getLineValue(howStartedIteratorRow);
								}
								else if(firstLinesHowStartedIteratorRow.startsWith(PB_ST_VAR_RECORD)) {
									List<String> recordNameAndId = getNameAndId(howStartedIteratorRow, '=');
									info.howTheInterviewStarted.recordId = getRelatedId(recordNameAndId?.get(0));
									info.howTheInterviewStarted.recordName = recordNameAndId?.get(1);
								}
								else if(firstLinesHowStartedIteratorRow.startsWith(PB_ST_VAR_RECORD_ID)) {
									info.howTheInterviewStarted.recordId = getRelatedId(getLineValue(howStartedIteratorRow, '='));
								}
								else if(firstLinesHowStartedIteratorRow.startsWith(PB_ST_VAR_SCHEDULED_PATH)) {
									info.howTheInterviewStarted.scheduledPath = getLineValue(howStartedIteratorRow);
								}
							}
						}
						else if(firstLinesPart?.startsWith(PB_ST_TRANSACTION_ERROR_HANDLED)) {
							FlowService.HTMLIterator errorMessageIterator = new FlowService.HTMLIterator(part, HTML_TAG_PARAGRAPH_OPEN, HTML_TAG_PARAGRAPH_CLOSE);
							while (errorMessageIterator.hasNext()) {
								info.handledErrorMessage = errorMessageIterator?.next()?.stripHtmlTags()?.trim();
								info.isHandledError = true;
								Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
								info.stacktraceElements.get(lastElementIndex).context.put(PB_ST_ELEMENT_FAULT_PATH_EXECUTED, true);
								break;
							}
						}
						else if (firstLinesStacktracePart?.startsWith(PB_ST_ORCHESTRATOR_ENTER_STAGE)) {
							FlowService.HTMLIterator orchestratorStacktraceIterator = new FlowService.HTMLIterator(stacktracePart, '<span style="font-weight:bold">');
							while (orchestratorStacktraceIterator.hasNext()) {
								String orchestratorElementIteratorRow = orchestratorStacktraceIterator.next();
								FlowService.HTMLIterator stacktraceElementIterator = new FlowService.HTMLIterator(orchestratorElementIteratorRow, HTML_TAG_BREAK_OPEN);
								while (stacktraceElementIterator.hasNext()) {
									String stacktraceElementIteratorRow = stacktraceElementIterator.next();
									switch on stacktraceElementIterator.count {
										when 1 {
											if (isValidStacktraceElement(stacktraceElementIteratorRow)) {
												List<String> typeAndNameElements = stacktraceElementIteratorRow.stripHtmlTags().split(':', 2);
												String type = typeAndNameElements.get(0).trim();
												String apiNameOrLabel = typeAndNameElements.get(1).trim();
												FlowStacktraceElement stacktraceElement = new FlowStacktraceElement(type, apiNameOrLabel);
												info.stacktraceElements.add(stacktraceElement);
											}
											if (stacktraceElementIteratorRow.startsWith('Flow (')) {
												Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
												String subflowApiName = stacktraceElementIteratorRow.stripHtmlTags().removeStart('Flow (').removeEnd(')');
												info.stacktraceElements.get(lastElementIndex).context.put('flowApiName', subflowApiName);
												info.orchestratorFailedFlowApiName = subflowApiName;
											}
										}
										when else {
											if (stacktraceElementIteratorRow?.stripHtmlTags().startsWith('Action:')) {
												Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
												String subflowApiName = stacktraceElementIterator?.next()?.stripHtmlTags()?.trim();
												info.stacktraceElements.get(lastElementIndex).context.put('flowApiName', subflowApiName);
												info.orchestratorFailedFlowApiName = subflowApiName;
											}
										}
									}
								}

							}
						}
						else {
							FlowService.HTMLIterator stacktraceElementIterator = new FlowService.HTMLIterator(stacktracePart, HTML_TAG_BREAK_OPEN);
							while (stacktraceElementIterator.hasNext()) {
								String stacktraceElementIteratorRow = stacktraceElementIterator.next();
								switch on stacktraceElementIterator.count {
									when 1 {
										if(isValidStacktraceElement(stacktraceElementIteratorRow)) {
											List<String> typeAndNameElements = stacktraceElementIteratorRow.stripHtmlTags().split(':', 2);
											String type = typeAndNameElements.get(0).trim();
											String apiNameOrLabel = typeAndNameElements.get(1).trim();
											FlowStacktraceElement stacktraceElement = new FlowStacktraceElement(type, apiNameOrLabel);
											if(type == PB_ST_ELEMENT_LOOP) {
												String nope = stacktraceElementIterator.next();
												String loopThroughOrEndLoop = stacktraceElementIterator?.next()?.stripHtmlTags()?.trim();
												if(!loopThroughOrEndLoop?.containsIgnoreCase(PB_ST_ELEMENT_LOOP_END)) {
													stacktraceElement.context.put(PB_ST_VAR_OUTCOME, PB_ST_ELEMENT_LOOP_OUTCOME_FOR_EACH);
												}
												else {
													stacktraceElement.context.put(PB_ST_VAR_OUTCOME, PB_ST_ELEMENT_LOOP_OUTCOME_LAST);
												}
											}
											
											info.stacktraceElements.add(stacktraceElement);
										}
									}
									when else {
										String stackTraceElementRow = stacktraceElementIteratorRow;
										String firstLinesStackTraceElementRow = getFirstLines(stackTraceElementRow);
										if (firstLinesStackTraceElementRow.startsWith(PB_ST_ELEMENT_RESULT)) {
											Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
											List<String> resultLines = info.stacktraceElements?.get(lastElementIndex)?.context?.get(PB_ST_ELEMENT_RESULT) != null
												? (List<String>)info.stacktraceElements?.get(lastElementIndex)?.context?.get(PB_ST_ELEMENT_RESULT)
												: new List<String>();
											while (stacktraceElementIterator.hasNext()) {
												String resultLine = stacktraceElementIterator?.next().stripHtmlTags()?.trim();
												if(String.isNotBlank(resultLine)) {
													resultLines.add(resultLine);
												}
											}
											info.stacktraceElements.get(lastElementIndex).context.put(PB_ST_ELEMENT_RESULT, resultLines);
										}
										else if(firstLinesStackTraceElementRow.containsIgnoreCase(PB_ST_DEFAULT_OUTCOME)) {
											Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
											info.stacktraceElements.get(lastElementIndex).context.put(PB_ST_VAR_OUTCOME, PB_ST_VAR_DEFAULT_OUTCOME);
										}
										else if(firstLinesStackTraceElementRow.startsWith(PB_ST_OUTCOME)) {
											Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
											String outcomeName = stacktraceElementIteratorRow.stripHtmlTags().split(':').get(1).trim();
											info.stacktraceElements.get(lastElementIndex).context.put(PB_ST_VAR_OUTCOME, outcomeName);
										}
										else if(firstLinesStackTraceElementRow.startsWith('Enter flow')) {
											Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
											String flowVersion = stacktraceElementIteratorRow.stripHtmlTags().split('version ').get(1).trim().removeEnd('.');
											String flowApiName = stacktraceElementIteratorRow.stripHtmlTags().split('version ').get(0).trim().removeStart('Enter flow ');
											info.stacktraceElements.get(lastElementIndex).context.put('flowApiName', flowApiName);
											info.stacktraceElements.get(lastElementIndex).context.put('apiVersion', flowVersion);
											info.stacktraceElements.get(lastElementIndex).context.put('enterFlow', true);
										}
										else if(firstLinesStackTraceElementRow.startsWith('Exit flow')) {
											Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
											String flowVersion = stacktraceElementIteratorRow.stripHtmlTags().split('version ').get(1).trim().removeEnd('.');
											String flowApiName = stacktraceElementIteratorRow.stripHtmlTags().split('version ').get(0).trim().removeStart('Exit flow ');
											info.stacktraceElements.get(lastElementIndex).context.put('flowApiName', flowApiName);
											info.stacktraceElements.get(lastElementIndex).context.put('apiVersion', flowVersion);
											info.stacktraceElements.get(lastElementIndex).context.put('enterFlow', false);
										}

									}

								}
							}
						}
					}
				}
				else if (firstLinesPart?.startsWith(getFlowElementErrorStarts())) {
					info.errorMessageHtml = getSingleErrorMessageHtml(part);
					info.errorMessage = info.errorMessageHtml?.stripHtmlTags()?.trim();
				}
				else if(firstLinesPart?.startsWith(PB_ST_TRANSACTION_ROLLED_BACK)) {
					info.handledErrorMessage = null;
					info.isHandledError = false;
				}
				else if(firstLinesPart?.startsWith(PB_ST_ERROR_OCCURED)) {
					FlowService.HTMLIterator errorMessageIterator = new FlowService.HTMLIterator(part, HTML_TAG_PARAGRAPH_OPEN, HTML_TAG_PARAGRAPH_CLOSE);
					while (errorMessageIterator.hasNext()) {
						String errorMessageHtml = errorMessageIterator?.next();
						String singleErrorMessageHtml;
						if(String.isNotBlank(errorMessageHtml) && errorMessageHtml.containsIgnoreCase(FLOW_ERROR_MESSAGE_SEPARATOR)) {
							List<String> parts = errorMessageHtml.split(FLOW_ERROR_MESSAGE_SEPARATOR);
							Integer lastElementIndex = parts?.size() != 0 ? parts?.size() - 1 : 0;
							singleErrorMessageHtml = parts.get(lastElementIndex);
						}
						else {
							singleErrorMessageHtml = errorMessageHtml;
						}
						if(String.isNotBlank(singleErrorMessageHtml) && singleErrorMessageHtml.containsIgnoreCase(FLOW_ERROR_MESSAGE_PART_OCCURRED)) {
							List<String> parts = singleErrorMessageHtml.split(FLOW_ERROR_MESSAGE_PART_OCCURRED);
							Integer lastElementIndex = parts?.size() != 0 ? parts?.size() - 1 : 0;
							singleErrorMessageHtml = parts.get(lastElementIndex);
						}
						info.errorMessage = singleErrorMessageHtml?.stripHtmlTags()?.trim();
						info.errorMessageHtml = singleErrorMessageHtml;
						break;
					}
				}
				else if(firstLinesPart?.startsWith(PB_ST_SALESFORCE_ERROR_ID)){
					FlowService.HTMLIterator salesforceErrorIterator = new FlowService.HTMLIterator(part, HTML_TAG_PARAGRAPH_OPEN, HTML_TAG_PARAGRAPH_CLOSE);
					while (salesforceErrorIterator.hasNext()) {
						info.salesforceErrorId = salesforceErrorIterator?.next()?.stripHtmlTags()?.trim();
						break;
					}
				}
			}
			partsIterator = null;
			if(this.headErrorStacktraceElement != null) {
				if(info.stacktraceElements?.isEmpty()) {
					info.stacktraceElements.add(this.headErrorStacktraceElement);
				}
				else {
					Integer lastElementIndex = info.stacktraceElements?.size() != 0 ? info?.stacktraceElements?.size() - 1 : 0;
					FlowStacktraceElement lastElement = info.stacktraceElements.get(lastElementIndex);
					if(lastElement == null
						|| (lastElement != null 
							&& lastElement.nameOrLabel != this.headErrorStacktraceElement.nameOrLabel
							&& lastElement.apiType != this.headErrorStacktraceElement.apiType)) {
						// error stacktrace element don't exist on the end of stacktrace
						info.stacktraceElements.add(this.headErrorStacktraceElement);
					}
				}
			}

			String flowFullNameWithVersion = getFlowApiNameWithVersion(info?.flowDetails?.flowApiName, info?.flowDetails?.version);
			info.flowApiNamePool.add(flowFullNameWithVersion);
			Integer indexFlow = info.flowApiNamePool.size() - 1;
			String flowName = (new List<String>(info.flowApiNamePool)).get(indexFlow);

			for(FlowStacktraceElement stElem : info.stacktraceElements) {
				
				if(stElem.type == 'SUBFLOW' && stElem.apiType == 'FlowSubflow') {
					String version = (String)stElem.context.get('apiVersion');
					String apiName = (String)stElem.context.get('flowApiName');
					Boolean isEnterFlow = (Boolean)stElem.context.get('enterFlow');
					
					
					String flowNameCurrent = getFlowApiNameWithVersion(apiName, version);
					if(info.flowApiNamePool.contains(flowNameCurrent)) {
						info.flowApiNamePool.remove(flowNameCurrent);
					}
					else {
						info.flowApiNamePool.add(flowNameCurrent);

						if(isEnterFlow) {
							if(info.stacktraceElementsMap.get(flowName) == null) {
								info.stacktraceElementsMap.put(flowName, new List<FlowStacktraceElement>());
							}
							info.stacktraceElementsMap.get(flowName).add(stElem);
						}
					}
					indexFlow = info.flowApiNamePool.size() - 1;
					flowName = (new List<String>(info.flowApiNamePool)).get(indexFlow);
					
				}
				else {
					if(info.stacktraceElementsMap.get(flowName) == null) {
						info.stacktraceElementsMap.put(flowName, new List<FlowStacktraceElement>());
					}
					info.stacktraceElementsMap.get(flowName).add(stElem);
				}
			}
			return info;
		}
	}

	public class FlowStacktraceInfo {

		public FlowDetails flowDetails;
		public FlowInterviewDetails flowInterviewDetails;
		public HowTheInterviewStarted howTheInterviewStarted;

		public List<FlowStacktraceElement> stacktraceElements;
		public Map<String, List<FlowStacktraceElement>> stacktraceElementsMap;
		public Set<String> flowApiNamePool;
		public String errorMessage;
		public String errorMessageHtml;
		public Boolean isHandledError;
		public String handledErrorMessage;
		public String salesforceErrorId;
		public Map<String, Object> context;
		public String orchestratorFailedFlowApiName;

		public FlowStacktraceInfo(){
			this.stacktraceElements = new List<FlowStacktraceElement>();
			this.stacktraceElementsMap = new Map<String, List<FlowStacktraceElement>>();
			this.flowApiNamePool = new Set<String>();
			this.context = new Map<String, Object>();
		}
	}

	public class FlowStacktraceElement {
		public String type;
		public String nameOrLabel;
		public Map<String, Object> context;
		public String apiType;

		public FlowStacktraceElement(String type, String nameOrLabel) {
			this.type = type;
			this.nameOrLabel = nameOrLabel;
			this.context = new Map<String, Object>();
			this.apiType = getAPITypeByLabel(this.type);
		}
		
		private String getAPITypeByLabel(String type) {
			if(type.containsIgnoreCase('UPDATE RECORDS')) {
				return 'FlowRecordUpdate';
			}
			else if(type.containsIgnoreCase('CREATE RECORDS')) {
				return 'FlowRecordCreate';
			}
			else if(type.containsIgnoreCase('GET RECORDS')) {
				return 'FlowRecordLookup';
			}
			else if(type.containsIgnoreCase('SCREEN')) {
				return 'FlowScreen';
			}
			else if(type.containsIgnoreCase('SCREEN')) {
				return 'FlowScreen';
			}
			else if(type.containsIgnoreCase('LOOP')) {
				return 'FlowLoop';
			}
			else if(type.containsIgnoreCase('ASSIGNMENT')) {
				return 'FlowAssignment';
			}
			else if(type.containsIgnoreCase('DECISION')) {
				return 'FlowDecision';
			}
			else if(type.containsIgnoreCase('(FLOWS)')) {
				return 'FlowSubflow';
			}
			else if(type.containsIgnoreCase('SUBFLOW')) {
				return 'FlowSubflow';
			}
			else if(type.containsIgnoreCase('(EMAIL ALERTS)')) {
				return 'FlowActionCall';
			}
			else if(type.containsIgnoreCase('ENTER STAGE')) {
				return 'FlowStage';
			}
			else if(type.containsIgnoreCase('BACKGROUND STEP')) {
				return 'FlowStep';
			}
			else if(type.containsIgnoreCase('SUBMIT FOR APPROVAL')) {
				return 'FlowActionCall';
			}
			else if(type.containsIgnoreCase('DELETE RECORDS')) {
				return 'FlowRecordDelete';
			}
			return '';
		}
	}

	public class FlowDetails {
		public String flowApiName;
		public String type;
		public String version;
		public String status;
		public String orgId;
		public String orgName;
	}

	public class FlowInterviewDetails {
		public String interviewLabel;
		public String interviewGUID;
		public String currentUserId;
		public String currentUserName;
		public String startTime;
		public String duration;
	}

	public class HowTheInterviewStarted {
		public String apiVersion;
		public String recordId;
		public String recordName;
		public String scheduledPath;
	}

	public class HTMLIterator implements Iterator<String>, Iterable<String> {
		private String data;
		private String startDelimeter;
		private String endDelimeter;
		private Integer startIndex = 0;
		public Integer count = 0;

		public HTMLIterator(String data, String startDelimeter) {
			this(data, startDelimeter, null);
		}

		public HTMLIterator(String data, String startDelimeter, String endDelimeter) {
			this.data = data;
			this.startDelimeter = startDelimeter;
			this.endDelimeter = endDelimeter;
		}

		public Boolean hasNext() {
			return startIndex < data.length() ? true : false;
		}

		public String next() {
			Integer endIndex = data.indexOf(startDelimeter, startIndex);
			if (count != 0 && endIndex != -1) {
				endIndex += startDelimeter.length();
			}
			if(endDelimeter != null && endIndex != -1) {
				startIndex = endIndex;
				endIndex = data.indexOf(endDelimeter, endIndex);
				if(endIndex != -1) {
					endIndex += endDelimeter.length();
				}
			}
			if (endIndex == -1 ) {
				endIndex = data.length();
			}

			String part = data.substring(startIndex , endIndex);
			startIndex = endIndex;
			count++;
			return part;
		}

		public Iterator<String> iterator() {
			return this;
		}

	}

	public static String getRelatedId(String message) {
		if (String.isBlank(message)) return null;
		Set<String> relatedIds = new Set<String>();
		Pattern p = ConfigUtil.SOBJECT_ID_PATTERN;
		Matcher pm = p.matcher(message);
		while (pm.find()) {
			relatedIds.add(pm.group(1));
		}
		return !relatedIds.isEmpty() ? new List<String>(relatedIds).get(relatedIds.size() - 1) : null;
	}

	public static List<String> getFlowExecutionPath(String htmlStackTrace) {
		List<String> result = new List<String>();
		FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(htmlStackTrace);
		FlowStacktraceInfo stackTraceInfo = sp.parse();
		for(FlowStacktraceElement ste : stackTraceInfo.stacktraceElements) {
			result.add(ste?.nameOrLabel);
		}
		return new List<String>(result);
	}

	// Process Builder Parser
	public static ProcessBuilder parseProcessBuilderStackTrace(String htmlStackTrace) {
		ProcessBuilder result = null;
		if(!isHtmlStacktrace(htmlStackTrace)) return result;

		FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(htmlStackTrace);
		FlowStacktraceInfo stackTraceInfo = sp.parse();

		if(String.isNotBlank(stackTraceInfo?.flowDetails?.flowApiName)) {
			ProcessBuilderHelper helper = new ProcessBuilderHelper();
			result = getProcessBuilder(getFlowApiNameWithVersion(stackTraceInfo?.flowDetails?.flowApiName, stackTraceInfo?.flowDetails?.version), helper);
			helper.replaceIdsByNames(result);
			if(!stackTraceInfo?.context?.isEmpty()) {
				result.context.putAll(stackTraceInfo?.context);
			}

			if(stackTraceInfo?.flowDetails != null) {
				result.context.put(PB_ST_VAR_FLOW_API_NAME_NAME, stackTraceInfo?.flowDetails?.flowApiName);
				result.context.put(PB_ST_VAR_TYPE_NAME, stackTraceInfo?.flowDetails?.type);
				result.context.put(PB_ST_VAR_VERSION_NAME, stackTraceInfo?.flowDetails?.version);
				result.context.put(PB_ST_VAR_STATUS_NAME, stackTraceInfo?.flowDetails?.status);
				result.context.put(PB_ST_VAR_ORG_NAME, stackTraceInfo?.flowDetails?.orgName);
			}
			if(stackTraceInfo?.flowInterviewDetails != null) {
				result.context.put(PB_ST_VAR_CURRENT_USER_NAME, stackTraceInfo?.flowInterviewDetails.currentUserName);
				result.context.put(PB_ST_VAR_START_TIME_NAME, stackTraceInfo?.flowInterviewDetails.startTime);
			}
			if(stackTraceInfo?.howTheInterviewStarted != null) {
				result.context.put(PB_ST_VAR_RUN_API_NAME, stackTraceInfo?.howTheInterviewStarted?.apiVersion);
			}

			for(FlowStacktraceElement fse : stackTraceInfo.stacktraceElements) {
				for(ProcessBuilderDecision pbd : result?.decisions) {
					if(pbd.name == fse.nameOrLabel){
						pbd.executed = true;
					}
					if(pbd.executed) {
						for(List<ProcessBuilderAction> pbaList : pbd?.actions) {
							for(ProcessBuilderAction pba : pbaList) {
								if (pba.name == fse.nameOrLabel || pba.label == fse.nameOrLabel) {
									pba.executed = true;
								}
							}
						}
					}
				}
			}

			result.errorMessage = stackTraceInfo?.errorMessage;
			result.errorMessageHtml = stackTraceInfo?.errorMessageHtml;
			try {
				result.apexStackTraceParseResults = StackTraceParser.parseStackTrace(result.errorMessageHtml);
			}
			catch(Exception e) {}
		}

		return result;
	}

	public static String getFlowApiNameWithVersion(String flowApiName, String flowVersion) {
		return flowApiName + (String.isNotBlank(flowVersion) ? ('-' + flowVersion) : '');
	}

	public static ProcessBuilder getProcessBuilder(String flowApiNameWithVersion, ProcessBuilderHelper helper) {
		ProcessBuilder result = new ProcessBuilder();

		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.setEndpointAndMetadataAPIVersion(StackTraceParser.corg.Instance_Url__c, PB_CURRENT_SUPPORTED_API_VERSION);
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = ConnectedOrgService.getConnectedOrgAccessToken(StackTraceParser.corg);
		MetadataService.Flow sfdcFlow =
			(MetadataService.Flow) service.readMetadata('Flow',
				new String[] {flowApiNameWithVersion}).getRecords()[0];

		if(sfdcFlow != null && sfdcFlow.fullName != null) {
			result.name = sfdcFlow.fullName;
			result.label = sfdcFlow.label;
			result.processType = sfdcFlow.processType;
			result.start = new ProcessBuilderStart(sfdcFlow.processType, sfdcFlow);
			getDecisions(result, sfdcFlow, helper);
		}
		if(result.decisions != null) {
			result.decisions.sort();
		}
		return result;
	}

	public static String getDecisionLabelByCriteriaName(MetadataService.FlowDecision flowDecision) {
		String result;
		if(flowDecision.rules != null) {
			for(MetadataService.FlowRule flowRule : flowDecision.rules) {
				result = flowRule?.label;
				break;
			}
		}
		return result;
	}

	public static void getDecisions(ProcessBuilder instance, MetadataService.Flow sfdcFlow, ProcessBuilderHelper helper) {
		if(sfdcFlow.decisions != null) {
			for(MetadataService.FlowDecision flowDecision : sfdcFlow.decisions) {
				Object decisionIndex = getProcessMetadataValue(PB_META_KEY_INDEX, flowDecision?.processMetadataValues);
				if(flowDecision != null && decisionIndex != null) {
					ProcessBuilderDecision fDecision = new ProcessBuilderDecision();
					fDecision.name = flowDecision.name;
					fDecision.label = getDecisionLabelByCriteriaName(flowDecision);
					fDecision.index = String.valueOf(decisionIndex);

					addDecisionSections(flowDecision, fDecision, sfdcFlow);

					List<String> firstActionNames = getFirstActionNameFromDecision(flowDecision);
					getDecisionActions(instance, firstActionNames, sfdcFlow, fDecision.actions, new Set<String>(), helper);
					instance.decisions.add(fDecision);

				}
			}
		}
		return;
	}

	public static Set<String> getMainDecisionNames(MetadataService.Flow sfdcFlow) {
		Set<String> result = new Set<String>();
		if(sfdcFlow?.decisions != null) {
			for(MetadataService.FlowDecision flowDecision : sfdcFlow.decisions) {
				Object decisionIndex = getProcessMetadataValue(PB_META_KEY_INDEX, flowDecision?.processMetadataValues);
				if(flowDecision != null && decisionIndex != null) {
					result.add(flowDecision.name);
				}
			}
		}
		return result;
	}

	public static void getDecisionActions(
		ProcessBuilder instance,
		String nextActionName,
		MetadataService.Flow sfdcFlow,
		List<List<ProcessBuilderAction>> actions,
		Set<String> apiNames,
		ProcessBuilderHelper helper) {
		getDecisionActions(instance, new List<String>{nextActionName}, sfdcFlow, actions, apiNames, helper);
	}

	public static void getDecisionActions(
		ProcessBuilder instance,
		List<String> nextActionNames,
		MetadataService.Flow sfdcFlow,
		List<List<ProcessBuilderAction>> actions,
		Set<String> apiNames,
		ProcessBuilderHelper helper) {

		for(String nextActionName : nextActionNames) {

			// check loop metadata
			if(apiNames.contains(nextActionName)) return;

			if(sfdcFlow.decisions != null) {
				for(MetadataService.FlowDecision fDecision : sfdcFlow.decisions) {
					Object decisionIndex = getProcessMetadataValue(PB_META_KEY_INDEX, fDecision.processMetadataValues);
					if(fDecision.name == nextActionName && decisionIndex == null) {
						if(fDecision.rules != null) {
							for(MetadataService.FlowRule flowRule : fDecision.rules) {
								if(flowRule != null && flowRule.connector != null && flowRule.connector.targetReference != null) {
									getDecisionActions(instance, flowRule.connector.targetReference, sfdcFlow, actions, apiNames, helper);
								}
							}
						}
					}
				}
			}

			if(sfdcFlow.waits != null) {
				for(MetadataService.FlowWait flowWait : sfdcFlow.waits) {
					if(flowWait.name == nextActionName) {
						for(MetadataService.FlowWaitEvent flowWaitEvent : flowWait.waitEvents) {
							if(!apiNames.contains(flowWaitEvent.name)) {
								addFlowWaitSections(flowWaitEvent, actions);
								apiNames.add(flowWaitEvent.name);
							}
							if(flowWaitEvent != null && flowWaitEvent.connector != null && flowWaitEvent.connector.targetReference != null) {
								getDecisionActions(instance, flowWaitEvent.connector.targetReference, sfdcFlow, actions, apiNames, helper);
							}
						}
						return;
					}
				}
			}

			if(sfdcFlow.assignments != null) {
				for(MetadataService.FlowAssignment flowAssignment : sfdcFlow.assignments) {
					if(flowAssignment.name == nextActionName) {
						if(!apiNames.contains(flowAssignment.name)) {
							apiNames.add(flowAssignment.name);
						}
						if(flowAssignment.connector != null && flowAssignment.connector.targetReference != null) {
							getDecisionActions(instance, flowAssignment.connector.targetReference, sfdcFlow, actions, apiNames, helper);
						}
						return;
					}
				}
			}

			if(sfdcFlow.actionCalls != null) {
				for(MetadataService.FlowActionCall actionCall : sfdcFlow.actionCalls) {
					if(actionCall.name == nextActionName) {
						if(!apiNames.contains(actionCall.name)) {
							addActionCallSections(actionCall, actions, helper, sfdcFlow);
							apiNames.add(actionCall.name);
						}
						if(actionCall.connector != null && actionCall.connector.targetReference != null) {
							getDecisionActions(instance, actionCall.connector.targetReference, sfdcFlow, actions, apiNames, helper);
						}
						return;
					}
				}
			}

			if(sfdcFlow.recordCreates != null) {
				for(MetadataService.FlowRecordCreate recordCreate : sfdcFlow.recordCreates) {
					if(recordCreate.name == nextActionName) {
						if(!apiNames.contains(recordCreate.name)) {
							addRecordCreateSections(recordCreate, actions, sfdcFlow);
							apiNames.add(recordCreate.name);
						}
						if(recordCreate.connector != null && recordCreate.connector.targetReference != null) {
							getDecisionActions(instance, recordCreate.connector.targetReference, sfdcFlow, actions, apiNames, helper);
						}
						return;
					}
				}
			}

			if(sfdcFlow.recordUpdates != null) {
				for(MetadataService.FlowRecordUpdate recordUpdate : sfdcFlow.recordUpdates) {
					if(recordUpdate.name == nextActionName) {
						if(!apiNames.contains(recordUpdate.name)) {
							addRecordUpdateSections(recordUpdate, actions, sfdcFlow);
							apiNames.add(recordUpdate.name);
						}
						if(recordUpdate.connector != null && recordUpdate.connector.targetReference != null) {
							getDecisionActions(instance, recordUpdate.connector.targetReference, sfdcFlow, actions, apiNames, helper);
						}
						return;
					}
				}
			}
		}
		return;
	}

	public static void addDecisionSections(MetadataService.FlowDecision flowDecision, ProcessBuilderDecision fDecision, MetadataService.Flow sfdcFlow) {
		if(flowDecision.rules != null) {
			for(MetadataService.FlowRule fRule : flowDecision.rules) {

				SideBarSection criteriaNameSection = new SideBarSection(PB_LABEL_CRITERIA_NAME, SideBarItemType.TEXT)
					.addText(fRule.label);
				fDecision.sections.add(criteriaNameSection);

				Boolean isCriteriaFormula = (!fRule.conditions.isEmpty()
					&& fRule.conditions.size() == 1
					&& fRule.conditions.get(0).leftValueReference.startsWith(PB_META_KEY_VALUE_FORMULA_PREFIX)
					&& getFlowFormulaExpression(fRule.conditions.get(0).leftValueReference, sfdcFlow) != 'true');
				Boolean isNoCriteries = (!fRule.conditions.isEmpty()
					&& fRule.conditions.size() == 1
					&& fRule.conditions.get(0).leftValueReference.startsWith(PB_META_KEY_VALUE_FORMULA_PREFIX)
					&& getFlowFormulaExpression(fRule.conditions.get(0).leftValueReference, sfdcFlow) == 'true');
				Boolean isCritariaConditions = !isCriteriaFormula && !isNoCriteries;

				SideBarSection executingCriteriaSection = new SideBarSection(PB_LABEL_CRITERIA_EXECUTING_ACTIONS, SideBarItemType.RADIOBUTTON)
					.addRadioButton(isCritariaConditions, PB_LABEL_CONDITIONS_MET)
					.addRadioButton(isCriteriaFormula, PB_LABEL_FORMULA_EVALUATE)
					.addRadioButton(isNoCriteries, PB_LABEL_NO_CRITERIES);
				fDecision.sections.add(executingCriteriaSection);

				if(isCriteriaFormula) {
					SideBarSection criteriaFormulaSection = new SideBarSection(PB_LABEL_BUILD_FORMULA, SideBarItemType.TEXTAREA)
						.addText(getFlowFormulaValue(fRule.conditions.get(0).leftValueReference, sfdcFlow));
					fDecision.sections.add(criteriaFormulaSection);
				}

				if(isCritariaConditions) {
					SideBarSection conditionsSection = new SideBarSection(PB_LABEL_SET_CONDITIONS, SideBarItemType.TABLE);
					Integer indexCounter = 1;
					conditionsSection.addTableHeaders(new List<String>{null, PB_TABLE_LABEL_SOURCE, PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_OPERATOR, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});

					if(fRule.conditions != null) {
						for(MetadataService.FlowCondition fc : fRule.conditions) {
							List<SideBarTableRow> rowObjects = new List<SideBarTableRow>();
							rowObjects.add(new SideBarTableRow(String.valueOf(indexCounter++)));
							rowObjects.add(new SideBarTableRow(fc?.leftValueReference));
							rowObjects.add(new SideBarTableRow(String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_TYPE, fc?.processMetadataValues))));
							rowObjects.add(new SideBarTableRow(OPERATORS_MAP.get(fc?.operator)));

							String rowType = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, fc?.processMetadataValues));
							rowObjects.add(new SideBarTableRow(rowType));

							String rowValue = String.valueOf(getFlowElementReferenceOrValue(fc?.rightValue));
							rowValue = (rowType == PB_META_KEY_VALUE_FORMULA) ? getFlowFormulaValue(rowValue, sfdcFlow) : rowValue;
							rowObjects.add(new SideBarTableRow(rowValue, (rowType == PB_META_KEY_VALUE_FORMULA)));

							conditionsSection.addTableRows(rowObjects);
						}
					}
					fDecision.sections.add(conditionsSection);

					SideBarSection conditionCriteriaSection = new SideBarSection(PB_LABEL_CRITERIA_EXECUTING_ACTIONS, SideBarItemType.RADIOBUTTON)
						.addRadioButton(fRule.conditionLogic == PB_META_KEY_VALUE_AND, PB_LABEL_ALL_CONDITIONS_MET)
						.addRadioButton(fRule.conditionLogic == PB_META_KEY_VALUE_OR, PB_LABEL_ANY_CONDITIONS_MET)
						.addRadioButton(fRule.conditionLogic != PB_META_KEY_VALUE_AND && fRule.conditionLogic != PB_META_KEY_VALUE_OR, PB_LABEL_CUSTOMIZE_LOGIC);
					fDecision.sections.add(conditionCriteriaSection);
				}
			}
		}
	}

	public static void addFlowWaitSections(MetadataService.FlowWaitEvent flowWaitEvent, List<List<ProcessBuilderAction>> actions) {
		ProcessBuilderAction pba = new ProcessBuilderAction(flowWaitEvent.name, flowWaitEvent.label, PB_ACTION_TYPE_SCHEDULED_ACTION_START);
		pba.setIcon(PB_ICON_SCHEDULED_ACTION);
		MetadataService.FlowWaitEventInputParameter timeOffsetUnit = getInputParameterByName(PB_META_KEY_TIME_OFFSET_UNIT, flowWaitEvent.inputParameters);
		MetadataService.FlowWaitEventInputParameter timeOffset = getInputParameterByName(PB_META_KEY_TIME_OFFSET, flowWaitEvent.inputParameters);
		String sTimeOffsetUnit = String.valueOf(getFlowElementReferenceOrValue(timeOffsetUnit.value));
		String sTimeOffset = String.valueOf(getFlowElementReferenceOrValue(timeOffset.value));
		Integer timeOffsetInteger = Integer.valueOf(sTimeOffset);

		switch on flowWaitEvent.eventType {
			when 'AlarmEvent' {
				SideBarSection timeSection = new SideBarSection(PB_LABEL_SET_TIME_FOR_ACTIONS, SideBarItemType.TABLETIME)
					.addTableRows(new List<SideBarTableRow>{
						new SideBarTableRow(false),
						new SideBarTableRow(''),
						new SideBarTableRow(PB_LABEL_DAYS),
						new SideBarTableRow(PB_LABEL_TIME_AFTER),
						new SideBarTableRow('')
					})
					.addTableRows(new List<SideBarTableRow>{
						new SideBarTableRow(true),
						new SideBarTableRow(Math.abs(timeOffsetInteger)),
						new SideBarTableRow(sTimeOffsetUnit),
						new SideBarTableRow(PB_LABEL_TIME_FROM_NOW)
					});
				pba.sections.add(timeSection);
				pba.label = timeOffsetInteger + ' ' + sTimeOffsetUnit + ' ' + PB_LABEL_TIME_FROM_NOW;
			}
			when 'DateRefAlarmEvent' {
				MetadataService.FlowWaitEventInputParameter timeFieldColumnEnumOrId = getInputParameterByName(PB_META_KEY_TIME_FIELD_ENUM_OR_ID, flowWaitEvent.inputParameters);
				String sTimeFieldColumnEnumOrId = String.valueOf(getFlowElementReferenceOrValue(timeFieldColumnEnumOrId.value));
				String isBeforeAfter = (timeOffsetInteger < 0) ? PB_LABEL_TIME_BEFORE : PB_LABEL_TIME_AFTER;
				SideBarSection timeSection = new SideBarSection(PB_LABEL_SET_TIME_FOR_ACTIONS, SideBarItemType.TABLETIME)
					.addTableRows(new List<SideBarTableRow>{
						new SideBarTableRow(true),
						new SideBarTableRow(Math.abs(timeOffsetInteger)),
						new SideBarTableRow(sTimeOffsetUnit),
						new SideBarTableRow(isBeforeAfter),
						new SideBarTableRow(sTimeFieldColumnEnumOrId)
					})
					.addTableRows(new List<SideBarTableRow>{
						new SideBarTableRow(false),
						new SideBarTableRow(''),
						new SideBarTableRow(PB_LABEL_DAYS),
						new SideBarTableRow(PB_LABEL_TIME_FROM_NOW)
					});
				pba.sections.add(timeSection);
				pba.label = Math.abs(timeOffsetInteger) + ' ' + sTimeOffsetUnit + ' ' + isBeforeAfter + ' ' + sTimeFieldColumnEnumOrId;
			}
		}
		actions.add(new List<ProcessBuilderAction>{pba});
	}

	public static void addActionCallSections(MetadataService.FlowActionCall actionCall, List<List<ProcessBuilderAction>> actions, ProcessBuilderHelper helper, MetadataService.Flow sfdcFlow) {
		Integer index = (actions.size() == 0) ? 0 : actions.size() - 1;
		ProcessBuilderAction pba = new ProcessBuilderAction(actionCall.name, actionCall.label, PB_ACTION_TYPE_FLOW_ACTION_CALL);
		Set<String> decisionNames = getMainDecisionNames(sfdcFlow);
		pba.evaluateNextCriteria = (actionCall.connector != null && actionCall.connector.targetReference != null && decisionNames.contains(actionCall.connector.targetReference));

		switch on actionCall.actionType {
			when 'submit' {
				pba.setIcon(PB_ICON_SUBMIT_FOR_APPROVAL);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				SideBarSection objectSection = new SideBarSection(PB_LABEL_OBJECT, SideBarItemType.TEXT)
					.addText(String.valueOf(getProcessMetadataValue(PB_KEY_OBJECT_TYPE, sfdcFlow.processMetadataValues)));
				pba.sections.add(objectSection);

				String selectionType = String.valueOf(getProcessMetadataValue(PB_META_KEY_SELECTION_TYPE, actionCall.processMetadataValues));
				switch on selectionType {
					when 'firstFound' {
						SideBarSection approvalProcessSection = new SideBarSection(PB_LABEL_APPROVAL_PROCESS, SideBarItemType.TEXT)
							.addText(PB_LABEL_DEFAULT_APPROVAL_PROCESS);
						pba.sections.add(approvalProcessSection);
					}
					when 'selectedProcess' {
						String processSelection = String.valueOf(getProcessMetadataValue(PB_META_KEY_PROCESS_SELECTION, actionCall.processMetadataValues));

						SideBarSection approvalProcessSection = new SideBarSection(PB_LABEL_APPROVAL_PROCESS, SideBarItemType.TABLE)
							.addTableHeaders(new List<String>{'', ''})
							.addTableRows(new List<SideBarTableRow>{
								new SideBarTableRow(PB_LABEL_SPECIFIC_APPROVAL_PROCESS),
								new SideBarTableRow(processSelection)
							});
						pba.sections.add(approvalProcessSection);

						if(actionCall.inputParameters != null && !actionCall.inputParameters.isEmpty()) {
							MetadataService.FlowActionCallInputParameter skipEntryCriteria = getInputParameterByName(PB_META_KEY_SKIP_ENTRY_CRITERIA, actionCall.inputParameters);
							Boolean sSkipEntryCriteria = Boolean.valueOf(getFlowElementReferenceOrValue(skipEntryCriteria.value));

							SideBarSection skipEntrySection = new SideBarSection(PB_LABEL_SKIP_ENTRY_CRITERIA, SideBarItemType.CHECKBOX)
								.addCheckBox(sSkipEntryCriteria, PB_LABEL_YES);
							pba.sections.add(skipEntrySection);
						}
					}
				}

				SideBarSection submitterSection = new SideBarSection(PB_LABEL_SUBMITTER, SideBarItemType.TEXT)
					.addText(String.valueOf(getProcessMetadataValue(PB_META_KEY_SUBMITTER_TYPE, actionCall.processMetadataValues)));
				pba.sections.add(submitterSection);

				if(actionCall.inputParameters != null && !actionCall.inputParameters.isEmpty()) {
					MetadataService.FlowActionCallInputParameter comments = getInputParameterByName(PB_META_KEY_COMMENT, actionCall.inputParameters);
					String sComments = String.valueOf(getFlowElementReferenceOrValue(comments.value));

					SideBarSection commentsSection = new SideBarSection(PB_LABEL_SUBMISSION_COMMENTS, SideBarItemType.TEXTAREA)
						.addText(sComments);
					pba.sections.add(commentsSection);
				}
			}
			when 'flow' {
				pba.setIcon(PB_ICON_FLOW);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				SideBarSection typeSection = new SideBarSection(PB_LABEL_ACTION_FLOW, SideBarItemType.TEXT)
					.addText(String.valueOf(getProcessMetadataValue(PB_META_KEY_FLOW_SELECTION, actionCall.processMetadataValues)));
				pba.sections.add(typeSection);
			}
			when 'customNotificationAction' {
				pba.setIcon(PB_ICON_CUSTOM_NOTIFICATION);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				SideBarSection typeSection = new SideBarSection(PB_LABEL_NOTIFICATION_TYPE, SideBarItemType.TEXT)
					.addText(String.valueOf(getProcessMetadataValue(PB_META_KEY_CUSTOM_NOTIFICATION_TYPE, actionCall.processMetadataValues)));
				pba.sections.add(typeSection);

				if(actionCall.inputParameters != null && !actionCall.inputParameters.isEmpty()) {
					MetadataService.FlowActionCallInputParameter title = getInputParameterByName(PB_META_KEY_TITLE, actionCall.inputParameters);
					MetadataService.FlowActionCallInputParameter body = getInputParameterByName(PB_META_KEY_BODY, actionCall.inputParameters);
					String sTitle = String.valueOf(getFlowElementReferenceOrValue(title.value));
					String sBody = String.valueOf(getFlowElementReferenceOrValue(body.value));

					String sRecipientCategory = String.valueOf(getProcessMetadataValue(PB_META_KEY_RECIPIENT_CATEGORY, actionCall.processMetadataValues));
					String recipientCategoryValue = '';
					String sRecipientType = (getProcessMetadataValue(PB_META_KEY_RECIPIENT_TYPE, actionCall.processMetadataValues) != null) ? String.valueOf(getProcessMetadataValue(PB_META_KEY_RECIPIENT_TYPE, actionCall.processMetadataValues)) : '';
					String recipientTypeValue = '';

					switch on sRecipientCategory {
						when 'user' {
							recipientCategoryValue = PB_LABEL_QA_RECIPIENT_CATEGORY_USER;

							switch on sRecipientType {
								when 'currentUser' {
									recipientTypeValue = PB_LABEL_QA_RECIPIENT_CATEGORY_USER_CURRENT_USER;
									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_NOTIFICATION_RECIPIENT, PB_TABLE_LABEL_USER})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(recipientTypeValue)
										});
									pba.sections.add(recipientSection);
								}
								when 'user' {
									recipientTypeValue = PB_LABEL_QA_RECIPIENT_CATEGORY_USER_FIND_USER;
									String sRecipientSelection = String.valueOf(getProcessMetadataValue(PB_META_KEY_RECIPIENT_SELECTION, actionCall.processMetadataValues));

									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_NOTIFICATION_RECIPIENT, PB_TABLE_LABEL_USER, ''})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(recipientTypeValue),
											new SideBarTableRow(sRecipientSelection)
										});
									pba.sections.add(recipientSection);
								}
								when 'reference' {
									recipientTypeValue = PB_LABEL_QA_RECIPIENT_CATEGORY_USER_REFERENCE;

									MetadataService.FlowActionCallInputParameter recipientIds = getInputParameterByName(PB_META_KEY_RECIPIENT_IDS, actionCall.inputParameters);
									String sRecipientIds = String.valueOf(getFlowElementReferenceOrValue(recipientIds.value));
									String sRecipientIdsValue = getFlowAssigmentItemValue(sRecipientIds, sfdcFlow);

									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_NOTIFICATION_RECIPIENT, PB_TABLE_LABEL_USER, ''})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(recipientTypeValue),
											new SideBarTableRow(sRecipientIdsValue)
										});
									pba.sections.add(recipientSection);
								}
							}
						}
						when 'owner' {
							recipientCategoryValue = PB_LABEL_QA_RECIPIENT_CATEGORY_OWNER;
							switch on sRecipientType {
								when 'reference' {
									MetadataService.FlowActionCallInputParameter recipientIds = getInputParameterByName(PB_META_KEY_RECIPIENT_IDS, actionCall.inputParameters);
									String sRecipientIds = String.valueOf(getFlowElementReferenceOrValue(recipientIds.value));
									String sRecipientIdsValue = getFlowAssigmentItemValue(sRecipientIds, sfdcFlow);

									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_NOTIFICATION_RECIPIENT, ''})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(sRecipientIdsValue)
										});
									pba.sections.add(recipientSection);
								}
							}
						}
						when 'group' {
							recipientCategoryValue = PB_LABEL_QA_RECIPIENT_CATEGORY_GROUP;

							switch on sRecipientType {
								when 'record' {
									String sRecipientSelection = String.valueOf(getProcessMetadataValue(PB_META_KEY_RECIPIENT_SELECTION, actionCall.processMetadataValues));

									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_GROUP, ''})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(sRecipientSelection)
										});
									pba.sections.add(recipientSection);
								}
							}
						}
						when 'queue' {
							recipientCategoryValue = PB_LABEL_QA_RECIPIENT_CATEGORY_QUEUE;

							switch on sRecipientType {
								when 'record' {
									recipientTypeValue = PB_LABEL_QA_RECIPIENT_CATEGORY_QUEUE_RECORD;
									String sRecipientSelection = String.valueOf(getProcessMetadataValue(PB_META_KEY_RECIPIENT_SELECTION, actionCall.processMetadataValues));

									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_NOTIFICATION_RECIPIENT, PB_TABLE_LABEL_QUEUE, ''})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(recipientTypeValue),
											new SideBarTableRow(sRecipientSelection)
										});
									pba.sections.add(recipientSection);
								}
								when 'reference' {
									recipientTypeValue = PB_LABEL_QA_RECIPIENT_CATEGORY_QUEUE_REFERENCE;

									MetadataService.FlowActionCallInputParameter recipientIds = getInputParameterByName(PB_META_KEY_RECIPIENT_IDS, actionCall.inputParameters);
									String sRecipientIds = String.valueOf(getFlowElementReferenceOrValue(recipientIds.value));
									String sRecipientIdsValue = getFlowAssigmentItemValue(sRecipientIds, sfdcFlow);

									SideBarSection recipientSection = new SideBarSection('', SideBarItemType.TABLE)
										.addTableHeaders(new List<String>{PB_TABLE_LABEL_NOTIFICATION_RECIPIENT, PB_TABLE_LABEL_QUEUE, ''})
										.addTableRows(new List<SideBarTableRow>{
											new SideBarTableRow(recipientCategoryValue),
											new SideBarTableRow(recipientTypeValue),
											new SideBarTableRow(sRecipientIdsValue)
										});
									pba.sections.add(recipientSection);
								}
							}
						}
					}

					SideBarSection titleSection = new SideBarSection(PB_LABEL_NOTIFICATION_TITLE, SideBarItemType.TEXTAREA)
						.addText(sTitle);
					pba.sections.add(titleSection);
					SideBarSection bodySection = new SideBarSection(PB_LABEL_NOTIFICATION_BODY, SideBarItemType.TEXTAREA)
						.addText(sBody);
					pba.sections.add(bodySection);
				}
			}
			when 'quickAction' {
				pba.setIcon(PB_ICON_QUICK_ACTION);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				String filterType = String.valueOf(getProcessMetadataValue(PB_META_KEY_FILTER_TYPE, actionCall.processMetadataValues));
				String quickActionType = String.valueOf(getProcessMetadataValue(PB_META_KEY_QA_TYPE, actionCall.processMetadataValues));
				String filterTypeValue = '';
				String qaTypeValue = '';

				switch on filterType {
					when 'quickActionType' {
						filterTypeValue = PB_LABEL_QA_FILTER_TYPE;
					}
					when 'globalType' {
						filterTypeValue = PB_LABEL_QA_FILTER_GLOBAL;
					}
					when 'objectType' {
						filterTypeValue = PB_LABEL_QA_FILTER_OBJECT;
					}
				}
				switch on quickActionType {
					when 'create' {
						qaTypeValue = PB_LABEL_QA_FILTER_CREATE;
					}
					when 'update' {
						qaTypeValue = PB_LABEL_QA_FILTER_UPDATE;
					}
					when 'logACall' {
						qaTypeValue = PB_LABEL_QA_FILTER_LOG_A_CALL;
					}
				}

				SideBarSection actionSection = new SideBarSection('', SideBarItemType.TABLE)
					.addTableHeaders(new List<String>{PB_TABLE_LABEL_FILTER_SEARCH_BY, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_ACTION})
					.addTableRows(new List<SideBarTableRow>{
						new SideBarTableRow(filterTypeValue),
						new SideBarTableRow(qaTypeValue),
						new SideBarTableRow(actionCall.actionName)
					});
				pba.sections.add(actionSection);

				if(actionCall.inputParameters != null && !actionCall.inputParameters.isEmpty()) {
					SideBarSection qaFieldSection = new SideBarSection(PB_LABEL_SET_QA_FIELD_VALUES, SideBarItemType.TABLE)
						.addTableHeaders(new List<String>{PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});
					for(MetadataService.FlowActionCallInputParameter ip : actionCall.inputParameters) {
						String fieldLabel = String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_LABEL, ip?.processMetadataValues));
						String rowType = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, ip?.processMetadataValues));
						String rowValue = String.valueOf(getFlowElementReferenceOrValue(ip?.value));

						qaFieldSection.addTableRows(new List<SideBarTableRow>{
							new SideBarTableRow(fieldLabel),
							new SideBarTableRow(rowType),
							new SideBarTableRow(rowValue)
						});
					}
					pba.sections.add(qaFieldSection);
				}
			}
			when 'chatterPost' {
				pba.setIcon(PB_ICON_CHATTER);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				if(actionCall.inputParameters != null && !actionCall.inputParameters.isEmpty()) {
					String postToValue;
					String sType;
					MetadataService.FlowActionCallInputParameter subjectNameOrId = getInputParameterByName(PB_META_KEY_SUBJECT_NAME_OR_ID, actionCall.inputParameters);
					MetadataService.FlowActionCallInputParameter ipType = getInputParameterByName(PB_META_KEY_TYPE, actionCall.inputParameters);
					String sSubjectNameOrId = String.valueOf(getFlowElementReferenceOrValue(subjectNameOrId.value));

					if(ipType.value == null) {
						postToValue = PB_LABEL_POST_TO_THIS_RECORD;
						SideBarSection postToSection = new SideBarSection(PB_LABEL_POST_TO, SideBarItemType.TEXT)
							.addText(sSubjectNameOrId);
						pba.sections.add(postToSection);
					}
					else {
						sType = String.valueOf(getFlowElementReferenceOrValue(ipType.value));
						if(sType == PB_META_KEY_VALUE_USER) {
							postToValue = PB_LABEL_POST_TO_CHATTER_USER;
							String userValue = (sSubjectNameOrId.startsWith(PB_META_KEY_VALUE_USER_ID_PREFIX)) ? PB_LABEL_SEARCH_USER : PB_LABEL_SELECT_USER;
							if(sSubjectNameOrId.startsWith(PB_META_KEY_VALUE_USER_ID_PREFIX)) {
								helper.userIds.add(sSubjectNameOrId);
								helper.actionNames.add(actionCall.name);
							}

							SideBarSection postToSection = new SideBarSection('', SideBarItemType.TABLE)
								.addTableHeaders(new List<String>{PB_TABLE_LABEL_POST_TO, PB_TABLE_LABEL_USER, null})
								.addTableRows(new List<SideBarTableRow>{
									new SideBarTableRow(postToValue),
									new SideBarTableRow(userValue),
									new SideBarTableRow(sSubjectNameOrId)
								});
							pba.sections.add(postToSection);
						}
						else if(sType == PB_META_KEY_VALUE_GROUP) {
							postToValue = PB_LABEL_POST_TO_CHATTER_GROUP;
							if(sSubjectNameOrId.startsWith(PB_META_KEY_VALUE_GROUP_ID_PREFIX)) {
								helper.groupIds.add(sSubjectNameOrId);
								helper.actionNames.add(actionCall.name);
							}
							SideBarSection postToSection = new SideBarSection('', SideBarItemType.TABLE)
								.addTableHeaders(new List<String>{PB_TABLE_LABEL_POST_TO, PB_TABLE_LABEL_GROUP})
								.addTableRows(new List<SideBarTableRow>{
									new SideBarTableRow(postToValue),
									new SideBarTableRow(sSubjectNameOrId)
								});
							pba.sections.add(postToSection);
						}
					}
				}

				String messageWrapperJson = String.valueOf(getProcessMetadataValue(PB_META_KEY_TEXT_JSON, actionCall.processMetadataValues));
				if(String.isNotBlank(messageWrapperJson)) {
					Map<String, Object> messageMap = (Map<String, Object>)JSON.deserializeUntyped(messageWrapperJson);
					if(messageMap != null && messageMap.containsKey(PB_META_KEY_MESSAGE)) {
						SideBarSection messageSection = new SideBarSection(PB_LABEL_MESSAGE, SideBarItemType.TEXTAREA)
							.addText(String.valueOf(messageMap.get(PB_META_KEY_MESSAGE)));
						pba.sections.add(messageSection);
					}
				}
			}
			when 'emailAlert' {
				pba.setIcon(PB_ICON_EMAIL_ALERT);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				SideBarSection emailAlertSection = new SideBarSection(PB_LABEL_EMAIL_ALERT, SideBarItemType.TEXT)
					.addText(String.valueOf(getProcessMetadataValue(PB_META_KEY_EMAIL_ALERT_SELECTION, actionCall.processMetadataValues)));
				pba.sections.add(emailAlertSection);
			}
			when 'apex' {
				pba.setIcon(PB_ICON_APEX);
				SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
					.addText(actionCall.label);
				pba.sections.add(actionNameSection);

				SideBarSection apexClassSection = new SideBarSection(PB_LABEL_APEX_CLASS, SideBarItemType.TEXT)
					.addText(String.valueOf(getProcessMetadataValue(PB_META_KEY_APEX_SELECTION, actionCall.processMetadataValues)));
				pba.sections.add(apexClassSection);

				if(actionCall.inputParameters != null && !actionCall.inputParameters.isEmpty()) {
					SideBarSection apexVariablesSection = new SideBarSection(PB_LABEL_SET_APEX_VARIABLES, SideBarItemType.TABLE)
						.addTableHeaders(new List<String>{PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});
					for(MetadataService.FlowActionCallInputParameter ip : actionCall.inputParameters) {
						String rowType = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, ip?.processMetadataValues));
						String rowTypeLabel = FILTER_TYPE_MAP.get(rowType);
						Boolean isFieldReference = rowType == PB_LABEL_SOBJECT;
						String rowValue;
						if(isFieldReference) {
							String variableName = String.valueOf(getFlowElementReferenceOrValue(ip?.value));
							MetadataService.FlowVariable variable = getFlowVariable(variableName, sfdcFlow);
							rowValue = variable?.objectType;
						}
						rowValue = (isFieldReference) ? rowValue : PB_LABEL_GLOBAL_CONSTANT_NULL;

						apexVariablesSection.addTableRows(new List<SideBarTableRow>{
							new SideBarTableRow(String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_LABEL, ip?.processMetadataValues))),
							new SideBarTableRow(rowTypeLabel),
							new SideBarTableRow(rowValue)
						});
					}
					pba.sections.add(apexVariablesSection);
				}
			}
		}
		actions.get(index).add(pba);
	}

	public static void addRecordCreateSections(MetadataService.FlowRecordCreate recordCreate, List<List<ProcessBuilderAction>> actions, MetadataService.Flow sfdcFlow) {
		Integer index = (actions.size() == 0) ? 0 : actions.size() - 1;
		ProcessBuilderAction pba = new ProcessBuilderAction(recordCreate.name, recordCreate.label, PB_ACTION_TYPE_FLOW_RECORD_CREATE);
		Set<String> decisionNames = getMainDecisionNames(sfdcFlow);
		pba.evaluateNextCriteria = (recordCreate.connector != null && recordCreate.connector.targetReference != null && decisionNames.contains(recordCreate.connector.targetReference));
		pba.setIcon(PB_ICON_RECORD_CREATE);
		actions.get(index).add(pba);
		SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
			.addText(recordCreate.label);
		pba.sections.add(actionNameSection);

		SideBarSection apexClassSection = new SideBarSection(PB_LABEL_RECORD_TYPE, SideBarItemType.TEXT)
			.addText(recordCreate.object_x);
		pba.sections.add(apexClassSection);

		if(recordCreate.inputAssignments != null && !recordCreate.inputAssignments.isEmpty()) {
			SideBarSection fieldValuesSection = new SideBarSection(PB_LABEL_SET_FIELD_VALUES, SideBarItemType.TABLE)
				.addTableHeaders(new List<String>{PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});
			for(MetadataService.FlowInputFieldAssignment ip : recordCreate.inputAssignments) {
				String fieldLabel = String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_LABEL, ip?.processMetadataValues));
				String fieldType = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, ip?.processMetadataValues));
				String fieldTypeLabel = FILTER_TYPE_MAP.get(fieldType);

				String rowValue = PB_LABEL_GLOBAL_CONSTANT_NULL;
				if(ip?.value != null) {
					rowValue = String.valueOf(getFlowElementReferenceOrValue(ip.value));
					rowValue = (fieldType == PB_META_KEY_VALUE_FORMULA) ? getFlowFormulaValue(rowValue, sfdcFlow) : rowValue;
					rowValue = (String.isBlank(rowValue)) ? PB_LABEL_GLOBAL_CONSTANT_EMPTY_STRING : rowValue;
				}

				fieldValuesSection.addTableRows(new List<SideBarTableRow>{
					new SideBarTableRow(fieldLabel),
					new SideBarTableRow(fieldTypeLabel),
					new SideBarTableRow(rowValue, (fieldType == PB_META_KEY_VALUE_FORMULA))
				});
			}
			pba.sections.add(fieldValuesSection);
		}
	}

	public static void addRecordUpdateSections(MetadataService.FlowRecordUpdate recordUpdate, List<List<ProcessBuilderAction>> actions, MetadataService.Flow sfdcFlow) {
		Integer index = (actions.size() == 0) ? 0 : actions.size() - 1;
		ProcessBuilderAction pba = new ProcessBuilderAction(recordUpdate.name, recordUpdate.label, PB_ACTION_TYPE_FLOW_RECORD_UPDATE);
		Set<String> decisionNames = getMainDecisionNames(sfdcFlow);
		pba.evaluateNextCriteria = (recordUpdate.connector != null && recordUpdate.connector.targetReference != null && decisionNames.contains(recordUpdate.connector.targetReference));
		pba.setIcon(PB_ICON_RECORD_UPDATE);
		actions.get(index).add(pba);
		SideBarSection actionNameSection = new SideBarSection(PB_LABEL_ACTION_NAME, SideBarItemType.TEXT)
			.addText(recordUpdate.label);
		pba.sections.add(actionNameSection);

		SideBarSection recordSection = new SideBarSection(PB_LABEL_RECORD, SideBarItemType.TEXT)
			.addText(String.valueOf(getProcessMetadataValue(PB_META_KEY_REFERENCE, recordUpdate.processMetadataValues)));
		pba.sections.add(recordSection);

		if(recordUpdate.filters != null && !recordUpdate.filters.isEmpty()) {
			Boolean hasFilters = false;
			Integer indexCounter = 1;

			SideBarSection filterFiledSection = new SideBarSection(PB_LABEL_FILTER_RECORDS, SideBarItemType.TABLE)
				.addTableHeaders(new List<String>{null, PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_OPERATOR, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});

			for(MetadataService.FlowRecordFilter frf : recordUpdate.filters) {
				Boolean implicit = Boolean.valueOf(getProcessMetadataValue(PB_META_KEY_IMPLICIT, frf?.processMetadataValues));
				if(!implicit) {
					hasFilters = true;

					String fieldLabel = String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_LABEL, frf?.processMetadataValues));
					String fieldType = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, frf?.processMetadataValues));
					String fieldTypeLabel = FILTER_TYPE_MAP.get(fieldType);

					String fieldValue = PB_LABEL_GLOBAL_CONSTANT_NULL;
					if(frf?.value != null) {
						String sValue = getFlowElementReferenceOrValue(frf.value) != null ? String.valueOf(getFlowElementReferenceOrValue(frf.value)) : null;
						fieldValue = String.isNotBlank(sValue) ? sValue : PB_LABEL_GLOBAL_CONSTANT_EMPTY_STRING;
					}

					filterFiledSection.addTableRows(new List<SideBarTableRow>{
						new SideBarTableRow(String.valueOf(indexCounter++)),
						new SideBarTableRow(fieldLabel),
						new SideBarTableRow(OPERATORS_MAP.get(frf?.operator)),
						new SideBarTableRow(fieldTypeLabel),
						new SideBarTableRow(fieldValue)
					});
				}
			}

			SideBarSection criteriaUpdatingSection = new SideBarSection(PB_LABEL_CRITERIA_UPDATING, SideBarItemType.RADIOBUTTON)
				.addRadioButton(hasFilters, PB_LABEL_CRITERIA_UPDATING_ALL_CONDITIONS)
				.addRadioButton(!hasFilters, PB_LABEL_CRITERIA_UPDATING_NO_CONDITIONS);
			pba.sections.add(criteriaUpdatingSection);

			if(hasFilters) {
				pba.sections.add(filterFiledSection);
			}
		}

		if(recordUpdate.inputAssignments != null && !recordUpdate.inputAssignments.isEmpty()) {
			SideBarSection fieldValuesSection = new SideBarSection(PB_LABEL_SET_NEW_FIELD_VALUES, SideBarItemType.TABLE)
				.addTableHeaders(new List<String>{PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});
			for(MetadataService.FlowInputFieldAssignment ip : recordUpdate.inputAssignments) {
				String fieldLabel = String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_LABEL, ip?.processMetadataValues));
				String fieldType = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, ip?.processMetadataValues));
				String fieldTypeLabel = FILTER_TYPE_MAP.get(fieldType);

				String rowValue = PB_LABEL_GLOBAL_CONSTANT_NULL;
				if(ip?.value != null) {
					rowValue = String.valueOf(getFlowElementReferenceOrValue(ip.value));
					rowValue = (fieldType == PB_META_KEY_VALUE_FORMULA) ? getFlowFormulaValue(rowValue, sfdcFlow) : rowValue;
					rowValue = (String.isBlank(rowValue)) ? PB_LABEL_GLOBAL_CONSTANT_EMPTY_STRING : rowValue;
				}
				String rowValueLabel = String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_LABEL, ip?.processMetadataValues));
				if(String.isNotBlank(rowValueLabel)) {
					pba.context.put(rowValueLabel, rowValue);
				}
				rowValue = (String.isNotBlank(rowValueLabel)) ? rowValueLabel : rowValue;

				fieldValuesSection.addTableRows(new List<SideBarTableRow>{
					new SideBarTableRow(fieldLabel),
					new SideBarTableRow(fieldTypeLabel),
					new SideBarTableRow(rowValue, (fieldType == PB_META_KEY_VALUE_FORMULA))
				});
			}
			pba.sections.add(fieldValuesSection);
		}
	}

	public static final String PB_ACTION_TYPE_FLOW_RECORD_UPDATE = 'FlowRecordUpdate';
	public static final String PB_ACTION_TYPE_FLOW_RECORD_CREATE = 'FlowRecordCreate';
	public static final String PB_ACTION_TYPE_FLOW_ACTION_CALL = 'FlowActionCall';
	public static final String PB_ACTION_TYPE_SCHEDULED_ACTION_START = 'FlowWait';

	public static final String PB_ICON_RECORD_UPDATE = 'update_record';
	public static final String PB_ICON_RECORD_CREATE = 'create_record';
	public static final String PB_ICON_APEX = 'apex';
	public static final String PB_ICON_EMAIL_ALERT = 'send_email';
	public static final String PB_ICON_CHATTER = 'chatter';
	public static final String PB_ICON_QUICK_ACTION = 'quick_actions';
	public static final String PB_ICON_CUSTOM_NOTIFICATION = 'custom_notification';
	public static final String PB_ICON_FLOW = 'launch_flow';
	public static final String PB_ICON_SUBMIT_FOR_APPROVAL = 'submit_approval';
	public static final String PB_ICON_SCHEDULED_ACTION = 'clock';

	public static final String PB_KEY_OBJECT_TYPE = 'ObjectType';
	public static final String PB_KEY_OBJECT_VARIABLE = 'ObjectVariable';
	public static final String PB_KEY_OLD_OBJECT_VARIABLE = 'OldObjectVariable';
	public static final String PB_KEY_TRIGGER_TYPE = 'TriggerType';
	public static final String PB_KEY_EVENT_TYPE = 'EventType';

	public static final String PK_KEY_TRIGGER_TYPE_INSERT = 'onCreateOnly';
	public static final String PK_KEY_TRIGGER_TYPE_UPDATE = 'onAllChanges';

	public static final String PB_LABEL_PLATFORM_EVENT = 'Platform Event';
	public static final String PB_LABEL_OBJECT = 'Object';
	public static final String PB_LABEL_MATCHING_CONDITIONS = 'Matching Conditions';
	public static final String PB_LABEL_START_THE_PROCESS = 'Start the process';
	public static final String PB_LABEL_TRIGGER_TYPE_INSERT = 'only when a record is created';
	public static final String PB_LABEL_TRIGGER_TYPE_UPDATE = 'when a record is created or edited';
	public static final String PB_LABEL_RECURSION_RPOCESS = 'Recursion - Allow process to evaluate a record multiple times in a single save operation?';
	public static final String PB_LABEL_YES = 'Yes';
	public static final String PB_LABEL_SKIP_ENTRY_CRITERIA = 'Skip the entry criteria for this process?';
	public static final String PB_LABEL_APPROVAL_PROCESS = 'Approval Process';
	public static final String PB_LABEL_DEFAULT_APPROVAL_PROCESS = 'Default approval process';
	public static final String PB_LABEL_SPECIFIC_APPROVAL_PROCESS = 'Specific approval process';
	public static final String PB_LABEL_SET_NEW_FIELD_VALUES = 'Set new field values for the records you update';
	public static final String PB_LABEL_CRITERIA_UPDATING = 'Criteria for Updating Records';
	public static final String PB_LABEL_CRITERIA_UPDATING_ALL_CONDITIONS = 'Updated records meet all conditions';
	public static final String PB_LABEL_CRITERIA_UPDATING_NO_CONDITIONS = 'No criteria—just update the records!';
	public static final String PB_LABEL_FILTER_RECORDS = 'Filter the records you update based on these conditions';
	public static final String PB_LABEL_RECORD = 'Record';
	public static final String PB_LABEL_ACTION_NAME = 'Action Name';
	public static final String PB_LABEL_DAYS = 'Days';
	public static final String PB_LABEL_TIME_FROM_NOW = 'From now';
	public static final String PB_LABEL_SET_TIME_FOR_ACTIONS = 'Set Time for Actions to Execute';
	public static final String PB_LABEL_TIME_BEFORE = 'Before';
	public static final String PB_LABEL_TIME_AFTER = 'After';
	public static final String PB_LABEL_SUBMISSION_COMMENTS = 'Submission Comments';
	public static final String PB_LABEL_SUBMITTER = 'Submitter';
	public static final String PB_LABEL_ACTION_FLOW = 'Flow';
	public static final String PB_LABEL_RECORD_TYPE = 'Record Type';
	public static final String PB_LABEL_SET_FIELD_VALUES = 'Set Field Values';
	public static final String PB_LABEL_GLOBAL_CONSTANT_NULL = '$GlobalConstant.Null';
	public static final String PB_LABEL_GLOBAL_CONSTANT_EMPTY_STRING = '$GlobalConstant.EmptyString';
	public static final String PB_LABEL_SOBJECT = 'SObject';
	public static final String PB_LABEL_SET_APEX_VARIABLES = 'Set Apex Variables';
	public static final String PB_LABEL_APEX_CLASS = 'Apex Class';
	public static final String PB_LABEL_EMAIL_ALERT = 'Email Alert';
	public static final String PB_LABEL_MESSAGE = 'Message';
	public static final String PB_LABEL_POST_TO = 'Post to';
	public static final String PB_LABEL_POST_TO_CHATTER_GROUP = 'Chatter Group';
	public static final String PB_LABEL_POST_TO_CHATTER_USER = 'User';
	public static final String PB_LABEL_POST_TO_THIS_RECORD = 'This Record';
	public static final String PB_LABEL_SEARCH_USER = 'Search for a user';
	public static final String PB_LABEL_SELECT_USER = 'Select a user from a record';
	public static final String PB_LABEL_SET_QA_FIELD_VALUES = 'Set Quick Action Field Values';
	public static final String PB_LABEL_QA_FILTER_TYPE = 'Type';
	public static final String PB_LABEL_QA_FILTER_GLOBAL = 'Global';
	public static final String PB_LABEL_QA_FILTER_OBJECT = 'Object';
	public static final String PB_LABEL_QA_FILTER_CREATE = 'Create a Record';
	public static final String PB_LABEL_QA_FILTER_UPDATE = 'Update a Record';
	public static final String PB_LABEL_QA_FILTER_LOG_A_CALL = 'Log a Call';
	public static final String PB_LABEL_NOTIFICATION_TITLE = 'Notification Title';
	public static final String PB_LABEL_NOTIFICATION_BODY = 'Notification Body';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_USER = 'User';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_OWNER = 'Owner';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_GROUP = 'Group';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_QUEUE = 'Queue';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_USER_CURRENT_USER = 'Current User';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_USER_FIND_USER = 'Find User';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_USER_REFERENCE = 'User Field from a Record';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_QUEUE_RECORD = 'Find Queue';
	public static final String PB_LABEL_QA_RECIPIENT_CATEGORY_QUEUE_REFERENCE = 'Queue Field from a Record';
	public static final String PB_LABEL_NOTIFICATION_TYPE = 'Notification Type';
	public static final String PB_LABEL_SET_CONDITIONS = 'Set Conditions';
	public static final String PB_LABEL_BUILD_FORMULA = 'Build Formula';
	public static final String PB_LABEL_ALL_CONDITIONS_MET = 'All of the conditions are met (AND)';
	public static final String PB_LABEL_ANY_CONDITIONS_MET = 'Any of the conditions are met (OR)';
	public static final String PB_LABEL_CRITERIA_EXECUTING_ACTIONS = 'Criteria for Executing Actions';
	public static final String PB_LABEL_CUSTOMIZE_LOGIC = 'Customize the logic';

	public static final String PB_TABLE_LABEL_FIELD = 'Field';
	public static final String PB_TABLE_LABEL_SOURCE = 'Source';
	public static final String PB_TABLE_LABEL_OPERATOR = 'Operator';
	public static final String PB_TABLE_LABEL_TYPE = 'Type';
	public static final String PB_TABLE_LABEL_VALUE = 'Value';
	public static final String PB_TABLE_LABEL_POST_TO = 'Post to';
	public static final String PB_TABLE_LABEL_GROUP = 'Group';
	public static final String PB_TABLE_LABEL_USER = 'User';
	public static final String PB_TABLE_LABEL_FILTER_SEARCH_BY = 'Filter Search By';
	public static final String PB_TABLE_LABEL_ACTION = 'Action';
	public static final String PB_TABLE_LABEL_NOTIFICATION_RECIPIENT = 'Notification Recipient';
	public static final String PB_TABLE_LABEL_QUEUE = 'Queue';
	public static final String PB_LABEL_CRITERIA_NAME = 'Criteria Name';
	public static final String PB_LABEL_CONDITIONS_MET = 'Conditions are met';
	public static final String PB_LABEL_FORMULA_EVALUATE = 'Formula evaluates to true';
	public static final String PB_LABEL_NO_CRITERIES = 'No criteria—just execute the actions!';

	public static final String PB_META_KEY_LEFT_HAND_SIDE_LABEL = 'leftHandSideLabel';
	public static final String PB_META_KEY_LEFT_HAND_SIDE_TYPE = 'leftHandSideType';
	public static final String PB_META_KEY_RIGHT_HAND_SIDE_TYPE = 'rightHandSideType';
	public static final String PB_META_KEY_RIGHT_HAND_SIDE_LABEL = 'rightHandSideLabel';
	public static final String PB_META_KEY_RECURSIVE_COUNT_VARIABLE = 'RecursiveCountVariable';
	public static final String PB_META_KEY_IMPLICIT = 'implicit';
	public static final String PB_META_KEY_REFERENCE = 'reference';
	public static final String PB_META_KEY_APEX_SELECTION = 'apexSelection';
	public static final String PB_META_KEY_EMAIL_ALERT_SELECTION = 'emailAlertSelection';
	public static final String PB_META_KEY_TEXT_JSON = 'textJson';
	public static final String PB_META_KEY_MESSAGE = 'message';
	public static final String PB_META_KEY_SUBJECT_NAME_OR_ID = 'subjectNameOrId';
	public static final String PB_META_KEY_TYPE = 'type';
	public static final String PB_META_KEY_FILTER_TYPE = 'filterType';
	public static final String PB_META_KEY_QA_TYPE = 'quickActionType';
	public static final String PB_META_KEY_RECIPIENT_IDS = 'recipientIds';
	public static final String PB_META_KEY_RECIPIENT_SELECTION = 'recipientSelection';
	public static final String PB_META_KEY_RECIPIENT_TYPE = 'recipientType';
	public static final String PB_META_KEY_RECIPIENT_CATEGORY = 'recipientCategory';
	public static final String PB_META_KEY_TITLE = 'title';
	public static final String PB_META_KEY_BODY = 'body';
	public static final String PB_META_KEY_CUSTOM_NOTIFICATION_TYPE = 'customNotifTypeName';
	public static final String PB_META_KEY_FLOW_SELECTION = 'flowSelection';
	public static final String PB_META_KEY_COMMENT = 'comment';
	public static final String PB_META_KEY_SUBMITTER_TYPE = 'submitterType';
	public static final String PB_META_KEY_SKIP_ENTRY_CRITERIA = 'skipEntryCriteria';
	public static final String PB_META_KEY_PROCESS_SELECTION = 'processSelection';
	public static final String PB_META_KEY_SELECTION_TYPE = 'selectionType';
	public static final String PB_META_KEY_TIME_FIELD_ENUM_OR_ID = 'TimeFieldColumnEnumOrId';
	public static final String PB_META_KEY_TIME_OFFSET ='TimeOffset';
	public static final String PB_META_KEY_TIME_OFFSET_UNIT ='TimeOffsetUnit';
	public static final String PB_META_KEY_VALUE_AND = 'and';
	public static final String PB_META_KEY_VALUE_OR = 'or';
	public static final String PB_META_KEY_VALUE_FORMULA = 'Formula';
	public static final String PB_META_KEY_INDEX = 'index';

	public static final String PB_META_KEY_VALUE_USER = 'USER';
	public static final String PB_META_KEY_VALUE_GROUP = 'GROUP';
	public static final String PB_META_KEY_VALUE_USER_ID_PREFIX = '005';
	public static final String PB_META_KEY_VALUE_GROUP_ID_PREFIX = '0F9';
	public static final String PB_META_KEY_VALUE_FORMULA_PREFIX = 'formula_';
	public static final String PB_META_KEY_VALUE_FIRST_DECISION_INDEX = '0.0';

	public static final String PB_ST_ERROR_OCCURED = 'Error Occurred:';
	public static final String PB_ST_TRANSACTION_ROLLED_BACK = 'Transaction Rolled Back';
	public static final String PB_ST_TRANSACTION_ERROR_HANDLED = 'Error Handled';
	public static final String PB_ST_ORCHESTRATOR_ENTER_STAGE = 'ENTER STAGE:';
	public static final String PB_ST_SALESFORCE_ERROR_ID ='Salesforce Error ID:';
	public static final String PB_ST_HOW_START = 'How the Interview Started';
	public static final String PB_ST_FLOW_INTERVIEW_DETAILS = 'Flow Interview Details';
	public static final String PB_ST_FLOW_VAR_INTERVIEW_LABEL = 'Interview Label';
	public static final String PB_ST_FLOW_VAR_INTERVIEW_GUID = 'Interview GUID';
	public static final String PB_ST_FLOW_DETAILS = 'Flow Details';
	public static final String PB_ST_FLOW_ERROR_DETAILS = 'Flow Error Details';
	public static final String PB_ST_FLOW_ERROR_ELEMENT = 'Error element';
	public static final String PB_ST_VAR_FLOW_API_NAME_LABEL = 'Flow API Name';
	public static final String PB_ST_VAR_FLOW_API_NAME_NAME = 'FlowAPIName';
	public static final String PB_ST_VAR_TYPE_LABEL = 'Type';
	public static final String PB_ST_VAR_TYPE_NAME = 'Type';
	public static final String PB_ST_VAR_STATUS_LABEL = 'Status';
	public static final String PB_ST_VAR_STATUS_NAME = 'Status';
	public static final String PB_ST_VAR_ORG_LABEL = 'Org';
	public static final String PB_ST_VAR_ORG_NAME = 'Org';
	public static final String PB_ST_VAR_VERSION_LABEL = 'Version';
	public static final String PB_ST_VAR_VERSION_NAME = 'Version';
	public static final String PB_ST_VAR_CURRENT_USER_LABEL = 'Current User';
	public static final String PB_ST_VAR_CURRENT_USER_NAME = 'CurrentUser';
	public static final String PB_ST_VAR_DURATION_LABEL = 'Duration';
	public static final String PB_ST_VAR_START_TIME_LABEL = 'Start time';
	public static final String PB_ST_VAR_START_TIME_NAME = 'StartTime';
	public static final String PB_ST_VAR_RUN_API_LABEL = 'API Version for Running the Flow';
	public static final String PB_ST_VAR_RUN_API_NAME = 'APIVersionforRunningtheFlow';
	public static final String PB_ST_VAR_RECORD = '$Record';
	public static final String PB_ST_VAR_RECORD_ID = 'recordId';
	public static final String PB_ST_VAR_SCHEDULED_PATH = 'Scheduled Path';
	public static final String PB_ST_ELEMENT_RESULT = 'Result';
	public static final String PB_ST_DEFAULT_OUTCOME = 'Default outcome executed';
	public static final String PB_ST_OUTCOME = 'Outcome executed';
	public static final String PB_ST_VAR_OUTCOME = 'Outcome';
	public static final String PB_ST_VAR_DEFAULT_OUTCOME = 'Default Outcome';
	public static final String PB_ST_ELEMENT_LOOP = 'LOOP';
	public static final String PB_ST_ELEMENT_LOOP_END = 'End Loop.';
	public static final String PB_ST_ELEMENT_LOOP_OUTCOME_FOR_EACH = 'For Each Item';
	public static final String PB_ST_ELEMENT_LOOP_OUTCOME_LAST = 'After Last Item';
	public static final String PB_ST_ELEMENT_FAULT_PATH_EXECUTED = 'FaultPathExecuted';
	public static final String PB_ST_START_ELEMENT = 'start';
	public static final String PB_ST_VAR_FAUTL = 'Fault';



	public static MetadataService.FlowWaitEventInputParameter getInputParameterByName(String name, List<MetadataService.FlowWaitEventInputParameter> parameters) {
		for(MetadataService.FlowWaitEventInputParameter ip : parameters) {
			if(ip?.name == name) {
				return ip;
			}
		}
		return null;
	}

	public static MetadataService.FlowActionCallInputParameter getInputParameterByName(String name, List<MetadataService.FlowActionCallInputParameter> parameters) {
		for(MetadataService.FlowActionCallInputParameter ip : parameters) {
			if(ip?.name == name) {
				return ip;
			}
		}
		return null;
	}

	public static MetadataService.FlowVariable getFlowVariable(String name, MetadataService.Flow sfdcFlow) {
		MetadataService.FlowVariable result;
		if(sfdcFlow.variables != null) {
			for(MetadataService.FlowVariable fVariable : sfdcFlow.variables) {
				if(fVariable?.name == name) {
					result = fVariable;
					break;
				}
			}
		}
		return result;
	}

	public static String getFlowAssigmentItemValue(String name, MetadataService.Flow sfdcFlow) {
		String result;
		if(sfdcFlow.assignments != null) {
			for(MetadataService.FlowAssignment assignment : sfdcFlow.assignments) {
				if(assignment?.assignmentItems != null) {
					for(MetadataService.FlowAssignmentItem assignmentItem : assignment.assignmentItems) {
						if(assignmentItem?.assignToReference == name) {
							result = String.valueOf(getFlowElementReferenceOrValue(assignment.assignmentItems.get(0)?.value));
							break;
						}
					}
				}
			}
		}
		return result;
	}

	public static MetadataService.FlowRecordLookup getRecordLookupByName(String recordLookupName, List<MetadataService.FlowRecordLookup> recordLookups) {
		MetadataService.FlowRecordLookup result;

		if(recordLookups != null) {
			for(MetadataService.FlowRecordLookup rl : recordLookups) {
				if(rl?.name == recordLookupName) {
					result = rl;
					break;
				}
			}
		}
		return result;
	}

	public static MetadataService.FlowDecision getDecisionByName(String decisionName, List<MetadataService.FlowDecision> decisions) {
		MetadataService.FlowDecision result;

		if(decisions != null) {
			for(MetadataService.FlowDecision fd : decisions) {
				if(fd?.name == decisionName) {
					result = fd;
					break;
				}
			}
		}
		return result;
	}

	public static List<String> getFirstActionNameFromDecision(MetadataService.FlowDecision flowDecision) {
		List<String> result = new List<String>();

		if(flowDecision.rules != null) {
			for(MetadataService.FlowRule flowRule : flowDecision.rules) {
				if(flowRule != null && flowRule.connector != null && flowRule.connector.targetReference != null) {
					result.add(flowRule.connector.targetReference);
				}
			}
		}
		if(result.isEmpty()) {
			if(flowDecision.defaultConnector != null && flowDecision.defaultConnector.targetReference != null) {
				result.add(flowDecision.defaultConnector.targetReference);
			}
		}
		return result;
	}

	public static String getNextDecisionName(MetadataService.FlowDecision flowDecision) {
		String result;
		if(flowDecision.defaultConnector != null && flowDecision.defaultConnector.targetReference != null) {
			result = flowDecision.defaultConnector.targetReference;
		}
		return result;
	}

	public static String getFlowFormulaValue(String flowFormulaName, MetadataService.Flow sfdcFlow) {
		String result;
		if(sfdcFlow.formulas != null) {
			for(MetadataService.FlowFormula ff : sfdcFlow.formulas) {
				if(ff?.name == flowFormulaName) {
					result = String.valueOf(getProcessMetadataValue('originalFormula', ff?.processMetadataValues));
					break;
				}
			}
		}
		return result;
	}

	public static String getFlowFormulaExpression(String flowFormulaName, MetadataService.Flow sfdcFlow) {
		String result;
		if(sfdcFlow.formulas != null) {
			for(MetadataService.FlowFormula ff : sfdcFlow.formulas) {
				if(ff?.name == flowFormulaName) {
					result = ff?.expression;
					break;
				}
			}
		}
		return result;
	}

	public static Object getProcessMetadataValue(String key, MetadataService.FlowMetadataValue[] processMetadataValues) {
		Object result;
		if(processMetadataValues != null) {
			for(MetadataService.FlowMetadataValue flowValue : processMetadataValues) {
				if(flowValue?.name == key) {
					result = getFlowElementReferenceOrValue(flowValue?.value);
					break;
				}
			}
		}
		return result;
	}

	public static Object getFlowElementReferenceOrValue(MetadataService.FlowElementReferenceOrValue value) {
		Object result;
		if(value == null) return null;
		if(value.booleanValue != null) {
			return value.booleanValue;
		}
		else if(value.dateTimeValue != null) {
			return value.dateTimeValue;
		}
		else if(value.dateValue != null) {
			return value.dateValue;
		}
		else if(value.elementReference != null) {
			return value.elementReference;
		}
		else if(value.numberValue != null) {
			return value.numberValue;
		}
		else if(value.stringValue != null) {
			return value.stringValue;
		}
		else if(value.transformValueReference != null) {
			return value.transformValueReference;
		}
		return result;
	}

	public static MetadataService.FlowDecision getFirstFlowDecision(MetadataService.Flow sfdcFlow) {
		if(sfdcFlow.decisions != null) {
			for(MetadataService.FlowDecision flowDecision : sfdcFlow.decisions) {
				String index = String.valueOf(getProcessMetadataValue(PB_META_KEY_INDEX, flowDecision?.processMetadataValues));
				if(PB_META_KEY_VALUE_FIRST_DECISION_INDEX == index) {
					return flowDecision;
				}
			}
		}
		return null;
	}

	public static String getLineValue(List<String> lines, String paramName) {
		return getLineValue(lines, paramName, ':');
	}

	private static String getLineValue(List<String> lines, String paramName, String separator) {
		for(String line : lines) {
			if(String.isNotBlank(line)) {
				if(line.containsIgnoreCase(paramName)) {
					List<String> paramValuePar = line.split(separator);
					if(paramValuePar.size() == 2) {
						String value = paramValuePar.get(1).trim();
						return value;
					}
				}
			}
		}
		return null;
	}

	public static final Map<String, String> OPERATORS_MAP = new Map<String, String>{
		'EqualTo' => 'Equals',
		'NotEqualTo' => 'Does not equal',
		'StartsWith' => 'Starts with',
		'EndsWith' => 'Ends With',
		'Contains' => 'Contains',
		'IsNull' => 'Is null',
		'GreaterThan' => 'Greater than',
		'GreaterThanOrEqualTo' => 'Greater than or equal',
		'LessThan' => 'Less than',
		'LessThanOrEqualTo' => 'Less than or equal'
	};

	public static final Map<String, String> FILTER_TYPE_MAP = new Map<String, String>{
		'String' => 'String',
		'Reference' => 'Field Reference',
		'GlobalConstant' => 'Global Constant',
		'Formula' => 'Formula',
		'Picklist' => 'Picklist',
		'DateTime' => 'Date/Time',
		'Date' => 'Date',
		'Currency' => 'Currency',
		'Number' => 'Number',
		'ID' => 'ID',
		'User' => 'User',
		'Boolean' => 'Boolean',
		'Queue' => 'Queue'
	};

	public Enum SideBarItemType {
		TEXT,
		CHECKBOX,
		RADIOBUTTON,
		TABLE,
		INDEX,
		TEXTAREA,
		TABLETIME
	}

	public class SideBarSection {
		public String label;
		public Object value;
		public SideBarItemType itemType;
		public List<String> headers;
		public List<List<SideBarTableRow>> rows;
		public List<SideBarSimpleRow> items;

		public SideBarSection(String label, SideBarItemType itemType) {
			this.label = label;
			this.itemType = itemType;
		}

		public SideBarSection addText(Object value) {
			this.value = value;
			return this;
		}

		public SideBarSection addCheckBox(Object value, String label) {
			if(this.items == null) {
				this.items = new List<SideBarSimpleRow>();
			}
			this.items.add(new SideBarSimpleRow(value, label));
			return this;
		}

		public SideBarSection addRadioButton(Object value, String label) {
			if(this.items == null) {
				this.items = new List<SideBarSimpleRow>();
			}
			this.items.add(new SideBarSimpleRow(value, label));
			return this;
		}

		public SideBarSection addTableHeaders(List<String> headers) {
			this.headers = headers;
			return this;
		}

		public SideBarSection addTableRows(List<SideBarTableRow> rows) {
			if(this.rows == null) {
				this.rows = new List<List<SideBarTableRow>>();
			}
			this.rows.add(rows);
			return this;
		}
	}

	public class SideBarTableRow {
		public Object v;
		public Boolean f;

		public SideBarTableRow(Object value) {
			this.v = value;
			this.f = false;
		}
		public SideBarTableRow(Object value, Boolean isFunction) {
			this.v = value;
			this.f = isFunction;
		}
	}

	public class SideBarSimpleRow {
		public Object v;
		public String l;

		public SideBarSimpleRow(Object value, String label) {
			this.v = value;
			this.l = label;
		}
	}

	public class ProcessBuilderHelper {
		public List<String> userIds;
		public List<String> groupIds;
		public Map<String, String> mapUsers;
		public Map<String, String> mapGroups;
		public Set<String> actionNames;

		public ProcessBuilderHelper() {
			this.userIds = new List<String>();
			this.groupIds = new List<String>();
			this.mapUsers = new Map<String, String>();
			this.mapGroups = new Map<String, String>();
			this.actionNames = new Set<String>();
		}

		public void replaceIdsByNames(ProcessBuilder result) {
			if(!this.actionNames.isEmpty()) {
				if(!this.userIds.isEmpty()) {
					this.mapUsers = getUserMaps(this.userIds);
				}
				if(!this.groupIds.isEmpty()) {
					this.mapGroups = getGroupMaps(this.groupIds);
				}
			}
			for(ProcessBuilderDecision decision : result.decisions) {
				for(List<ProcessBuilderAction> actions : decision.actions) {
					for(ProcessBuilderAction action : actions) {
						if(this.actionNames.contains(action.name)) {
							for(SideBarSection sideBarSection : action.sections) {
								if(sideBarSection.itemType == SideBarItemType.TABLE) {
									for(List<SideBarTableRow> row : sideBarSection.rows) {
										SideBarTableRow lastCellInRow = row.get(row.size() - 1);
										String idValue = String.valueOf(lastCellInRow.v);
										if(this.userIds.contains(idValue)) {
											String name = this.mapUsers.get(idValue);
											if(String.isNotBlank(name)) {
												row.get(row.size() - 1).v = name;
											}
										}
										if(this.groupIds.contains(idValue)) {
											String name = this.mapGroups.get(idValue);
											if(String.isNotBlank(name)) {
												row.get(row.size() - 1).v = name;
											}
										}
									}
								}
							}
						}
					}
				}
			}

		}
	}

	public class ProcessBuilder {
		public String name;
		public String label;
		public String processType;
		public ProcessBuilderStart start;
		public List<ProcessBuilderDecision> decisions;
		public Map<String, Object> context;
		public List<StackTraceParser.StackTraceParseResult> apexStackTraceParseResults;
		public String errorMessage;
		public String errorMessageHtml;

		public ProcessBuilder(){
			this.start = new ProcessBuilderStart();
			this.decisions = new List<ProcessBuilderDecision>();
			this.context = new Map<String, Object>();
			this.apexStackTraceParseResults = new List<StackTraceParser.StackTraceParseResult>();
		}
	}

	public class ProcessBuilderDecision implements Comparable {
		public String name;
		public String label;
		public String index;
		public Boolean executed;
		public List<List<ProcessBuilderAction>> actions;
		public Map<String, Object> context;

		public List<SideBarSection> sections;

		public ProcessBuilderDecision() {
			this.executed = false;
			this.actions = new List<List<ProcessBuilderAction>>();
			this.actions.add(new List<ProcessBuilderAction>());
			this.context = new Map<String, Object>();

			this.sections = new List<SideBarSection>();
		}

		public Integer compareTo(Object compareTo) {
			ProcessBuilderDecision mf = (ProcessBuilderDecision)compareTo;
			if (Integer.valueOf(this.index) == Integer.valueOf(mf.index)) return 0;
			if (Integer.valueOf(this.index) > Integer.valueOf(mf.index)) return 1;
			return -1;
		}
	}

	public class ProcessBuilderAction {
		public String name;
		public String label;
		public String actionType;
		public Boolean executed;
		public Boolean evaluateNextCriteria;
		public Map<String, Object> context;
		public String icon;

		public List<SideBarSection> sections;

		public ProcessBuilderAction(String name, String label, String actionType) {
			this.name = name;
			this.label = label;
			this.actionType = actionType;
			this.executed = false;
			this.context = new Map<String, Object>();

			this.sections = new List<SideBarSection>();
			this.evaluateNextCriteria = false;
		}

		public void setIcon(String icon) {
			this.icon = icon;
		}

	}

	public class ProcessBuilderStart {
		public String startType;
		public String objectType;
		public String objectVariable;
		public String oldObjectVariable;
		public String triggerType;
		public String eventType;

		public List<SideBarSection> sections;

		public ProcessBuilderStart(){}

		public ProcessBuilderStart(String startType, MetadataService.Flow sfdcFlow) {

			this.startType = startType;
			this.objectType = String.valueOf(getProcessMetadataValue(PB_KEY_OBJECT_TYPE, sfdcFlow.processMetadataValues));
			this.objectVariable = String.valueOf(getProcessMetadataValue(PB_KEY_OBJECT_VARIABLE, sfdcFlow.processMetadataValues));
			this.oldObjectVariable = String.valueOf(getProcessMetadataValue(PB_KEY_OLD_OBJECT_VARIABLE, sfdcFlow.processMetadataValues));
			this.triggerType = String.valueOf(getProcessMetadataValue(PB_KEY_TRIGGER_TYPE, sfdcFlow.processMetadataValues));
			this.eventType = String.valueOf(getProcessMetadataValue(PB_KEY_EVENT_TYPE, sfdcFlow.processMetadataValues));

			this.sections = new List<SideBarSection>();
			// started from PlatformEvent
			if(String.isNotBlank(this.eventType) && this.eventType != 'null') {
				SideBarSection eventSection = new SideBarSection(PB_LABEL_PLATFORM_EVENT, SideBarItemType.TEXT)
					.addText(this.eventType);

				SideBarSection objectSection = new SideBarSection(PB_LABEL_OBJECT, SideBarItemType.TEXT)
					.addText(this.objectType);

				this.sections.add(eventSection);
				this.sections.add(objectSection);

				String startRefferenceName = sfdcFlow.startElementReference;
				if(String.isNotBlank(startRefferenceName)) {
					MetadataService.FlowRecordLookup recordLookup = getRecordLookupByName(startRefferenceName, sfdcFlow.recordLookups);
					if(recordLookup != null) {
						SideBarSection conditionsSection = new SideBarSection(PB_LABEL_MATCHING_CONDITIONS, SideBarItemType.TABLE);
						Integer indexCounter = 1;
						conditionsSection.addTableHeaders(new List<String>{null, PB_TABLE_LABEL_FIELD, PB_TABLE_LABEL_OPERATOR, PB_TABLE_LABEL_TYPE, PB_TABLE_LABEL_VALUE});

						if(recordLookup.filters != null) {
							for(MetadataService.FlowRecordFilter frf : recordLookup.filters) {
								List<SideBarTableRow> rowObjects = new List<SideBarTableRow>();
								rowObjects.add(new SideBarTableRow(String.valueOf(indexCounter++)));
								rowObjects.add(new SideBarTableRow(String.valueOf(getProcessMetadataValue(PB_META_KEY_LEFT_HAND_SIDE_LABEL, frf?.processMetadataValues))));
								rowObjects.add(new SideBarTableRow(OPERATORS_MAP.get(frf?.operator)));
								rowObjects.add(new SideBarTableRow(String.valueOf(getProcessMetadataValue(PB_META_KEY_RIGHT_HAND_SIDE_TYPE, frf?.processMetadataValues))));
								rowObjects.add(new SideBarTableRow(getFlowElementReferenceOrValue(frf?.value)));
								conditionsSection.addTableRows(rowObjects);
							}
						}
						this.sections.add(conditionsSection);
					}
				}
			}
			// started from Record change
			else {
				SideBarSection objectSection = new SideBarSection(PB_LABEL_OBJECT, SideBarItemType.TEXT)
					.addText(this.objectType);

				SideBarSection howStartSection = new SideBarSection(PB_LABEL_START_THE_PROCESS, SideBarItemType.RADIOBUTTON)
					.addRadioButton(this.triggerType == PK_KEY_TRIGGER_TYPE_INSERT, PB_LABEL_TRIGGER_TYPE_INSERT)
					.addRadioButton(this.triggerType == PK_KEY_TRIGGER_TYPE_UPDATE, PB_LABEL_TRIGGER_TYPE_UPDATE);

				String recursionValue = String.valueOf(getProcessMetadataValue(PB_META_KEY_RECURSIVE_COUNT_VARIABLE, sfdcFlow.processMetadataValues));
				SideBarSection recursionSection = new SideBarSection(PB_LABEL_RECURSION_RPOCESS, SideBarItemType.CHECKBOX)
					.addCheckBox(recursionValue != 'null', PB_LABEL_YES);

				this.sections.add(objectSection);
				this.sections.add(howStartSection);
				this.sections.add(recursionSection);

			}
		}
	}

	public static Map<String, String> getUserMaps(List<String> userIds) {
		return getUserOrGroupMaps('User', userIds);
	}

	public static Map<String, String> getGroupMaps(List<String> groupIds) {
		return getUserOrGroupMaps('CollaborationGroup', groupIds);
	}

	public static Map<String, String> getUserOrGroupMaps(String objectName, List<String> recordIds) {
		Map<String, String> result = new Map<String, String>();
		String query = new QBuilder(objectName)
			.selectFields(new Set<String>{'Id', 'Name'})
			.add(QBuilder.condition('Id').isIn(recordIds))
			.buildToolingQuery();
		String b = HttpUtils.get(
			StackTraceParser.corg.Instance_Url__c + ConfigUtil.QUERY_REST_API_PATH + query,
			StackTraceParser.getHeaders(),
				200
		);

		Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(b);
		List<Object> recordList = (List<Object>)results.get('records');
		for(Object recordItem : recordList) {
			Map<String, Object> mapRecord = (Map<String, Object>)recordItem;
			String name = (String)mapRecord.get('Name');
			String id = (String)mapRecord.get('Id');
			result.put(id, name);
		}

		return result;
	}


	// Flow parser
	public static final String FLOW_CURRENT_SUPPORTED_API_VERSION = '61.0';
	public static final String FLOW_CONDITION_EMPTY = '';
	public static final String FLOW_CONDITION_EMPTY_LABEL = 'None—Get All Contact Records';
	public static final String FLOW_CONDITION_PAUSE_LABEL = 'Always Pause Flow—No Conditions';
	public static final String FLOW_CONDITION_OR = 'OR';
	public static final String FLOW_CONDITION_FORMULA = 'Formula';
	public static final String FLOW_CONDITION_OR_LABEL = 'Any Condition Is Met (OR)';
	public static final String FLOW_CONDITION_AND = 'AND';
	public static final String FLOW_CONDITION_AND_LABEL = 'All Conditions Are Met (AND)';
	public static final String FLOW_CONDITION_CUSTOM_LABEL = 'Custom Condition Logic Is Met';
	public static final String FLOW_CONDITION_FORMULA_LABEL = 'Formula Evaluets to True';

	public static final String FLOW_ELEMENT_COLLECTION_PROCESSOR = 'FlowCollectionProcessor';
	public static final String FLOW_ELEMENT_SORT_COLLECTION_PROCESSOR = 'SortCollectionProcessor';
	public static final String FLOW_ELEMENT_FILTER_COLLECTION_PROCESSOR = 'FilterCollectionProcessor';
	public static final String FLOW_ELEMENT_ICON_SORT_COLLECTION_PROCESSOR = 'sort_collection';
	public static final String FLOW_ELEMENT_ICON_FILTER_COLLECTION_PROCESSOR = 'filter_collection';
	public static final String FLOW_ELEMENT_ICON_ROLL_BACK_RECORDS = 'roll_back_records';

	public static final String FLOW_ELEMENT_CUSTOM_ERROR = 'FlowCustomError';
	public static final String FLOW_ELEMENT_ICON_CUSTOM_ERROR = 'custom_error';

	public static Boolean isHtmlStacktrace(String htmlStacktrace) {
		return (String.isNotBlank(htmlStackTrace) && htmlStacktrace?.startsWithIgnoreCase('<'));
	}

	public static Flow parseFlowStackTrace(String htmlStackTrace) {
		Flow result = null;
		List<Flow> subflows = new List<Flow>();
		if(!isHtmlStacktrace(htmlStackTrace)) return result;

		Integer edgeIndex = 1;
		FlowService.FlowStacktraceParser sp = new FlowService.FlowStacktraceParser(htmlStackTrace);
		FlowStacktraceInfo stackTraceInfo = sp.parse();

		List<String> flowApiNamesForRetrieve = new List<String>(stackTraceInfo?.stacktraceElementsMap.keySet());
		List<Flow> sfdcFlows = getSfdcFlows(flowApiNamesForRetrieve, FLOW_CURRENT_SUPPORTED_API_VERSION);
		Map<String, Flow> sfdcFlowsMap = new Map<String, Flow>();
		for(Flow sfdcFlow : sfdcFlows) {
			if(flowApiNamesForRetrieve.contains(sfdcFlow?.name)) {
				sfdcFlowsMap.put(sfdcFlow?.name, sfdcFlow);
			}
			else {
				for(String sfFlowName : flowApiNamesForRetrieve) {
					String sfName = sfFlowName.split('-').get(0);
					if(sfName?.startsWith(sfdcFlow?.name) || sfName?.endsWith(sfdcFlow?.name)) {
						sfdcFlowsMap.put(sfName, sfdcFlow);
						break;
					}
				}
			}
		}
		for(String sfdcFlowName : new List<String>(flowApiNamesForRetrieve)) {
			Flow sfdcFlow = sfdcFlowsMap.get(sfdcFlowName);
			if(sfdcFlow == null && sfdcFlowName.contains('-')) {
				String sfName = sfdcFlowName.split('-').get(0);
				sfdcFlow = sfdcFlowsMap.get(sfName);
			}
			if(sfdcFlow?.name?.startsWith(stackTraceInfo?.flowDetails?.flowApiName)) {
				if(stackTraceInfo?.flowDetails != null) {
					sfdcFlow.context.put(PB_ST_VAR_FLOW_API_NAME_NAME, stackTraceInfo?.flowDetails?.flowApiName);
					sfdcFlow.context.put(PB_ST_VAR_TYPE_NAME, stackTraceInfo?.flowDetails?.type);
					sfdcFlow.context.put(PB_ST_VAR_VERSION_NAME, stackTraceInfo?.flowDetails?.version);
					sfdcFlow.context.put(PB_ST_VAR_STATUS_NAME, stackTraceInfo?.flowDetails?.status);
					sfdcFlow.context.put(PB_ST_VAR_ORG_NAME, stackTraceInfo?.flowDetails?.orgName);
				}
				if(stackTraceInfo?.flowInterviewDetails != null) {
					sfdcFlow.context.put(PB_ST_VAR_CURRENT_USER_NAME, stackTraceInfo?.flowInterviewDetails.currentUserName);
					sfdcFlow.context.put(PB_ST_VAR_START_TIME_NAME, stackTraceInfo?.flowInterviewDetails.startTime);
				}
				if(stackTraceInfo?.howTheInterviewStarted != null) {
					sfdcFlow.context.put(PB_ST_VAR_RUN_API_NAME, stackTraceInfo?.howTheInterviewStarted?.apiVersion);
				}
			}
			
			Map<String, List<FlowElement>> mapElementsByApiNameOrLabel = new Map<String, List<FlowElement>>();
			for(String elementName : sfdcFlow?.elements?.keySet()) {
				FlowElement flowElement = sfdcFlow?.elements?.get(elementName);
				List<FlowElement> elementsApi = mapElementsByApiNameOrLabel.containsKey(flowElement?.name)
					? mapElementsByApiNameOrLabel.get(flowElement?.name)
					: new List<FlowElement>();
				List<FlowElement> elementsLabel = mapElementsByApiNameOrLabel.containsKey(flowElement?.label)
					? mapElementsByApiNameOrLabel.get(flowElement?.label)
					: new List<FlowElement>();

				elementsApi.add(flowElement);
				elementsLabel.add(flowElement);
				mapElementsByApiNameOrLabel.put(flowElement?.name, elementsApi);
				mapElementsByApiNameOrLabel.put(flowElement?.label, elementsLabel);
			}

			FlowElement nextFlowElement;
			if(sfdcFlow?.edges?.containsKey(PB_ST_START_ELEMENT)) {
				Set<FlowEdge> edges = sfdcFlow?.edges?.get(PB_ST_START_ELEMENT);
				if(edges?.size() == 1 && String.isBlank(stackTraceInfo?.howTheInterviewStarted?.scheduledPath)) {
					for(FlowEdge edge : edges) {
						edge.addIndex(edgeIndex++);
						nextFlowElement = sfdcFlow?.elements?.get(edge.target);
					}
					sfdcFlow.edges.put(PB_ST_START_ELEMENT, new Set<FlowEdge>(edges));
				}
				if(String.isNotBlank(stackTraceInfo?.howTheInterviewStarted?.scheduledPath)) {
					for(FlowEdge edge : edges) {
						if(edge?.label == stackTraceInfo?.howTheInterviewStarted?.scheduledPath || edge?.name == stackTraceInfo?.howTheInterviewStarted?.scheduledPath) {
							nextFlowElement = sfdcFlow?.elements?.get(edge.target);
							edge.addIndex(edgeIndex++);
							break;
						}
					}
				}
			}

			for(Integer i = 0; i < stackTraceInfo.stacktraceElementsMap?.get(sfdcFlow.name)?.size(); i++) {
				FlowStacktraceElement fse = stackTraceInfo.stacktraceElementsMap.get(sfdcFlow.name).get(i);
				Boolean isLastStacktraceElement = (i == stackTraceInfo.stacktraceElementsMap.get(sfdcFlow.name).size() - 1);
				String outcome = (!fse?.context?.isEmpty() && fse?.context?.containsKey(PB_ST_VAR_OUTCOME))
					? String.valueOf(fse?.context?.get(PB_ST_VAR_OUTCOME))
					: null;
				Boolean isFaultPath = !fse?.context?.isEmpty() && fse?.context?.containsKey(PB_ST_ELEMENT_FAULT_PATH_EXECUTED);
				List<FlowElement> matchedElements = mapElementsByApiNameOrLabel.get(fse.nameOrLabel);
				if(nextFlowElement != null) {
					matchedElements = mapElementsByApiNameOrLabel.get(nextFlowElement.name);
				}
				
				// filter matched elements by api type
				if(String.isNotBlank(fse.apiType) && matchedElements?.size() > 1) {
					List<FlowElement> metchedByType = new List<FlowElement>();
					for(FlowElement stElement : matchedElements) {
						if(stElement.actionType == fse.apiType) {
							metchedByType.add(stElement);
						}
					}
					matchedElements = metchedByType;
				}
				
				if(matchedElements?.size() == 1) {
					FlowElement flowElement = sfdcFlow?.elements?.get(matchedElements?.get(0)?.name);
					flowElement.executed = true;
					if(!fse?.context?.isEmpty()) {
						flowElement?.context?.putAll(fse.context);
					}
					Set<FlowEdge> edges = sfdcFlow?.edges?.get(matchedElements?.get(0)?.name);
					if(isLastStacktraceElement) continue;
					if(edges?.size() == 1) {
						for(FlowEdge edge : edges) {
							if(edge.fault && !isFaultPath) continue;
							edge.addIndex(edgeIndex++);
							nextFlowElement = sfdcFlow?.elements?.get(edge.target);
						}
						sfdcFlow.edges.put(flowElement.name, new Set<FlowEdge>(edges));
					}
					else if(edges?.size() > 1) {
						for(FlowEdge edge : edges) {
							if(String.isNotBlank(outcome) && (edge?.label == outcome || edge?.name == outcome || (outcome == PB_ST_VAR_DEFAULT_OUTCOME && edge.isDefault))) {
								edge.addIndex(edgeIndex++);
								nextFlowElement = sfdcFlow?.elements?.get(edge.target);
							}
							else if(isFaultPath && edge?.label == PB_ST_VAR_FAUTL) {
								edge.addIndex(edgeIndex++);
								nextFlowElement = sfdcFlow?.elements?.get(edge.target);
							}
						}
						if(edges?.size() == 2 && String.isBlank(outcome) && !isFaultPath) {
							for(FlowEdge edge : edges) {
								if(edge?.label != PB_ST_VAR_FAUTL) {
									edge.addIndex(edgeIndex++);
									nextFlowElement = sfdcFlow?.elements?.get(edge.target);
									break;
								}
							}
						}
						sfdcFlow.edges.put(flowElement.name, new Set<FlowEdge>(edges));
					}
				}
			}
			
			if(sfdcFlow?.name?.startsWith(stackTraceInfo?.flowDetails?.flowApiName) 
				|| stackTraceInfo?.flowDetails?.flowApiName?.endsWith(sfdcFlow?.name)) {
				result = sfdcFlow;
			}
			else {
				subflows.add(sfdcFlow);
			}
		}
		
		result.subflows.addAll(subflows);
		result.errorMessage = stackTraceInfo?.errorMessage;
		result.errorMessageHtml = stackTraceInfo?.errorMessageHtml;
		result.orchestratorFailedFlowApiName = stackTraceInfo?.orchestratorFailedFlowApiName;
		try {
			result.apexStackTraceParseResults = StackTraceParser.parseStackTrace(result.errorMessageHtml);
		}
		catch(Exception e) {}

		return result;
	}

	public static List<Flow> getSFDCFlows(List<String> flowApiNames, String metadataApiVersion) {
		List<Flow> results = new List<Flow>();

		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.setEndpointAndMetadataAPIVersion(StackTraceParser.corg.Instance_Url__c, metadataApiVersion);
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = ConnectedOrgService.getConnectedOrgAccessToken(StackTraceParser.corg);
		List<MetadataService.Flow> sfdcFlows =
			(List<MetadataService.Flow>) service.readMetadata('Flow',
				flowApiNames).getRecords();
		
		for(MetadataService.Flow sfdcFlow : sfdcFlows) {
			if(sfdcFlow != null && sfdcFlow.fullName != null) {
				Flow result = new Flow();
				result.name = sfdcFlow.fullName;
				result.label = sfdcFlow.label;
				result.description = sfdcFlow.description;
				result.processType = sfdcFlow.processType;
				result.start = new FlowStart(sfdcFlow.processType, sfdcFlow);
				if(result?.start?.startRefference != null) {
					getFlowElements(result, sfdcFlow, result.start.startRefference);
				}
				if(sfdcFlow?.startElementReference != null) {
					result.addEdge(PB_ST_START_ELEMENT, sfdcFlow.startElementReference, false);
				}
				if(sfdcFlow?.start?.connector != null && sfdcFlow?.start?.connector?.targetReference != null) {
					result.addEdge(PB_ST_START_ELEMENT, sfdcFlow.start.connector.targetReference, 'Run Immediately', sfdcFlow.start.connector.isGoTo);
					getFlowElements(result, sfdcFlow, sfdcFlow.start.connector.targetReference);
				}
				if(sfdcFlow?.start?.scheduledPaths != null) {
					for(MetadataService.FlowScheduledPath scheduledPath : sfdcFlow.start.scheduledPaths) {
						result.addEdge(PB_ST_START_ELEMENT, scheduledPath?.connector?.targetReference, scheduledPath?.label, scheduledPath?.name, scheduledPath?.connector?.isGoTo);
						getFlowElements(result, sfdcFlow, scheduledPath?.connector?.targetReference);
					}
				}
				if(sfdcFlow?.variables != null && !sfdcFlow?.variables?.isEmpty()) {
					for(MetadataService.FlowVariable fv : sfdcFlow?.variables) {
						FlowVariable nfv = new FlowVariable();
						nfv.name = fv.name;
						nfv.description = fv.description;
						nfv.apexClass = fv.apexClass;
						nfv.isCollection = fv.isCollection;
						nfv.isInput = fv.isInput;
						nfv.isOutput = fv.isOutput;
						nfv.objectType = fv.objectType;
						nfv.dataType = fv.dataType;
						result.variables.add(nfv);
					}
				}
				
				results.add(result);
			}
		}
		return results;
	}

	public static Flow getSFDCFlow(String flowApiNameWithVersion) {
		return getSFDCFlow(flowApiNameWithVersion, FLOW_CURRENT_SUPPORTED_API_VERSION);
	}

	public static Flow getSFDCFlow(String flowApiNameWithVersion, String metadataApiVersion) {
		Flow result = new Flow();

		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.setEndpointAndMetadataAPIVersion(StackTraceParser.corg.Instance_Url__c, metadataApiVersion);
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = ConnectedOrgService.getConnectedOrgAccessToken(StackTraceParser.corg);
		MetadataService.Flow sfdcFlow =
			(MetadataService.Flow) service.readMetadata('Flow',
				new String[] {flowApiNameWithVersion}).getRecords()[0];

		if(sfdcFlow != null && sfdcFlow.fullName != null) {
			result.name = sfdcFlow.fullName;
			result.label = sfdcFlow.label;
			result.processType = sfdcFlow.processType;
			result.start = new FlowStart(sfdcFlow.processType, sfdcFlow);
			if(result?.start?.startRefference != null) {
				getFlowElements(result, sfdcFlow, result.start.startRefference);
			}
			if(sfdcFlow?.startElementReference != null) {
				result.addEdge(PB_ST_START_ELEMENT, sfdcFlow.startElementReference, false);
			}
			if(sfdcFlow?.start?.connector != null && sfdcFlow?.start?.connector?.targetReference != null) {
				result.addEdge(PB_ST_START_ELEMENT, sfdcFlow.start.connector.targetReference, 'Run Immediately', sfdcFlow.start.connector.isGoTo);
				getFlowElements(result, sfdcFlow, sfdcFlow.start.connector.targetReference);
			}
			if(sfdcFlow?.start?.scheduledPaths != null) {
				for(MetadataService.FlowScheduledPath scheduledPath : sfdcFlow.start.scheduledPaths) {
					result.addEdge(PB_ST_START_ELEMENT, scheduledPath?.connector?.targetReference, scheduledPath?.label, scheduledPath?.name, scheduledPath?.connector?.isGoTo);
					getFlowElements(result, sfdcFlow, scheduledPath?.connector?.targetReference);
				}
			}
		}
		return result;
	}

	public class FlowHelper {
		public List<String> userIds;
		public List<String> groupIds;
		public List<String> queueIds;
		public Map<String, String> mapUsers;
		public Map<String, String> mapGroups;
		public Map<String, String> mapQueues;

		public FlowHelper() {
			this.userIds = new List<String>();
			this.groupIds = new List<String>();
			this.queueIds = new List<String>();
			this.mapUsers = new Map<String, String>();
			this.mapGroups = new Map<String, String>();
			this.mapQueues = new Map<String, String>();
		}

		public void replaceNamesByLabels(Flow result) {
			if(!this.userIds.isEmpty()) {
				this.mapUsers = getUserMaps(this.userIds);
			}
			if(!this.groupIds.isEmpty()) {
				this.mapGroups = getGroupMaps(this.groupIds);
			}
			if(!this.queueIds.isEmpty()) {
				this.mapQueues = getGroupMaps(this.queueIds);
			}
			for(String elementName : result?.elements?.keySet()) {
				FlowElement flowElement = result?.elements?.get(elementName);
				if(flowElement.actionType == 'FlowOrchestratedStage') {
					OrchestratedStagesInfo stageInfo = (OrchestratedStagesInfo)flowElement.metadataInfo;
					if(stageInfo?.stageSteps != null && !stageInfo?.stageSteps?.isEmpty()){
						for(StageStepsInfo stepInfo : stageInfo.stageSteps) {
							if(stepInfo?.actionType == 'stepInteractive' && String.isNotBlank(stepInfo?.assignee)) {
								if(stepInfo.assigneeType == 'User') {}
								else if(stepInfo.assigneeType == 'Group') {}
								else if(stepInfo.assigneeType == 'Queue') {}
							}
						}
					}
				}
			}
		}
	}

	public static void getFlowElements(Flow flow, MetadataService.Flow sfdcFlow, String nextRefferenceName) {
		if(String.isNotBlank(nextRefferenceName) && !flow.edges.containsKey(nextRefferenceName)) {

			if(sfdcFlow.orchestratedStages != null) {
				for(MetadataService.FlowOrchestratedStage orchestratedStage : sfdcFlow.orchestratedStages) {
					if(orchestratedStage != null && nextRefferenceName == orchestratedStage.name) {
						FlowElement fe = new FlowElement(orchestratedStage.name, orchestratedStage.label, 'FlowOrchestratedStage', orchestratedStage.locationX, orchestratedStage.locationY, orchestratedStage.description);
						fe.setIcon('flowOrchestratedStage');
						addFlowOrchestratedStagesInfo(fe, orchestratedStage);
						flow.elements.put(orchestratedStage.name, fe);
						if(orchestratedStage.connector != null && orchestratedStage.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, orchestratedStage.connector.targetReference, orchestratedStage.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, orchestratedStage.connector.targetReference);
						}
						if(orchestratedStage.faultConnector != null && orchestratedStage.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, orchestratedStage.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, orchestratedStage.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, orchestratedStage.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.collectionProcessors != null) {
				for(MetadataService.FlowCollectionProcessor cp : sfdcFlow.collectionProcessors) {
					if(cp != null && nextRefferenceName == cp.name) {
						FlowElement fe = new FlowElement(cp.name, cp.label, FLOW_ELEMENT_COLLECTION_PROCESSOR, cp.locationX, cp.locationY, cp.description);
						if(cp.elementSubtype == FLOW_ELEMENT_SORT_COLLECTION_PROCESSOR) {
							fe.setIcon(FLOW_ELEMENT_ICON_SORT_COLLECTION_PROCESSOR);
							addFlowSortCollectionProcessorInfo(fe, cp);
						}
						else if(cp.elementSubtype == FLOW_ELEMENT_FILTER_COLLECTION_PROCESSOR) {
							fe.setIcon(FLOW_ELEMENT_ICON_FILTER_COLLECTION_PROCESSOR);
							addFlowFilterCollectionProcessorInfo(fe, cp, sfdcFlow);
						}
						flow.elements.put(cp.name, fe);
						if(cp.connector != null && cp.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, cp.connector.targetReference, cp.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, cp.connector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.customErrors != null) {
				for(MetadataService.FlowCustomError customError : sfdcFlow.customErrors) {
					if(customError != null && nextRefferenceName == customError.name) {
						FlowElement fe = new FlowElement(customError.name, customError.label, FLOW_ELEMENT_CUSTOM_ERROR, customError.locationX, customError.locationY, customError.description);
						fe.setIcon(FLOW_ELEMENT_ICON_CUSTOM_ERROR);
						addFlowCustomErrorInfo(fe, customError);
						flow.elements.put(customError.name, fe);
						if(customError.connector != null && customError.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, customError.connector.targetReference, customError.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, customError.connector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.waits != null) {
				for(MetadataService.FlowWait flowWait : sfdcFlow.waits) {
					if(flowWait != null && nextRefferenceName == flowWait.name) {
						FlowElement fe = new FlowElement(flowWait.name, flowWait.label, 'FlowWait', flowWait.locationX, flowWait.locationY, flowWait.description);
						addFlowWaitInfo(fe, flowWait);
						flow.elements.put(flowWait.name, fe);
						if(flowWait.waitEvents != null) {
							for(MetadataService.FlowWaitEvent fwe : flowWait.waitEvents) {
								if(fwe != null && fwe.connector != null && fwe.connector.targetReference != null) {
									flow.addEdge(nextRefferenceName, fwe.connector.targetReference, getFlowWaitEventLabel(fwe, flowWait), fwe.name, fwe.connector.isGoTo);
									getFlowElements(flow,  sfdcFlow, fwe.connector.targetReference);
								}
							}
						}

						if(flowWait.defaultConnector != null && flowWait.defaultConnector.targetReference != null) {
							flow.addDefaultEdge(nextRefferenceName, flowWait.defaultConnector.targetReference, flowWait.defaultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, flowWait.defaultConnector.targetReference);
						}
						if(flowWait.faultConnector != null && flowWait.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, flowWait.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, flowWait.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, flowWait.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.transforms != null) {
				for(MetadataService.FlowTransform flowTransform : sfdcFlow.transforms) {
					if(flowTransform != null && nextRefferenceName == flowTransform.name) {
						FlowElement fe = new FlowElement(flowTransform.name, flowTransform.label, 'FlowTransform', flowTransform.locationX, flowTransform.locationY, flowTransform.description);
						fe.setIcon('transform');
						addFlowTransformInfo(fe, flowTransform);
						flow.elements.put(flowTransform.name, fe);
						if(flowTransform.connector != null && flowTransform.connector.targetReference != null) {
							flow.addDefaultEdge(nextRefferenceName, flowTransform.connector.targetReference, '', flowTransform.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, flowTransform.connector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.subflows != null) {
				for(MetadataService.FlowSubflow subFlow : sfdcFlow.subflows) {
					if(subFlow != null && nextRefferenceName == subFlow.name) {
						FlowElement fe = new FlowElement(subFlow.name, subFlow.label, 'FlowSubflow', subFlow.locationX, subFlow.locationY, subFlow.description);
						fe.setIcon('sub_flow');
						addSubFlowInfo(fe, subFlow);
						flow.elements.put(subFlow.name, fe);
						if(subFlow.connector != null && subFlow.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, subFlow.connector.targetReference, subFlow.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, subFlow.connector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.loops != null) {
				for(MetadataService.FlowLoop flowLoop : sfdcFlow.loops) {
					if(flowLoop != null && nextRefferenceName == flowLoop.name) {
						FlowElement fe = new FlowElement(flowLoop.name, flowLoop.label, 'FlowLoop', flowLoop.locationX, flowLoop.locationY, flowLoop.description);
						fe.setIcon('loop');
						addFlowLoopInfo(fe, flowLoop);
						flow.elements.put(flowLoop.name, fe);
						if(flowLoop.nextValueConnector != null && flowLoop.nextValueConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, flowLoop.nextValueConnector.targetReference, 'For Each Item', flowLoop.nextValueConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, flowLoop.nextValueConnector.targetReference);
						}
						if(flowLoop.noMoreValuesConnector != null && flowLoop.noMoreValuesConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, flowLoop.noMoreValuesConnector.targetReference, 'After Last Item', flowLoop.noMoreValuesConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, flowLoop.noMoreValuesConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.assignments != null) {
				for(MetadataService.FlowAssignment fa : sfdcFlow.assignments) {
					if(fa != null && nextRefferenceName == fa.name) {
						FlowElement fe = new FlowElement(fa.name, fa.label, 'FlowAssignment', fa.locationX, fa.locationY, fa.description);
						fe.setIcon('assignment');
						addAssignmentInfo(fe, fa);
						flow.elements.put(fa.name, fe);

						if(fa.connector != null && fa.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fa.connector.targetReference, fa.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fa.connector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.decisions != null) {
				for(MetadataService.FlowDecision fd : sfdcFlow.decisions) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowDecision', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('decision');
						addDecisionInfo(fe, fd);
						flow.elements.put(fe.name, fe);
						if(fd.defaultConnector != null && fd.defaultConnector.targetReference != null) {
							String edgeLabel = fd.defaultConnectorLabel;
							flow.addDefaultEdge(nextRefferenceName, fd.defaultConnector.targetReference, edgeLabel, fd.defaultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.defaultConnector.targetReference);
						}
						if(fd.rules != null) {
							for(MetadataService.FlowRule fdr : fd.rules) {
								if(fdr != null && fdr.connector != null && fdr.connector.targetReference != null) {
									flow.addEdge(nextRefferenceName, fdr.connector.targetReference, fdr.label, fdr.name, fdr.connector.isGoTo);
									getFlowElements(flow,  sfdcFlow, fdr.connector.targetReference);
								}
							}
						}
					}
				}
			}

			if(sfdcFlow.recordCreates != null) {
				for(MetadataService.FlowRecordCreate fd : sfdcFlow.recordCreates) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowRecordCreate', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('record_create');
						addRecordsCreateInfo(fe, fd, sfdcFlow);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
						if(fd.faultConnector != null && fd.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, fd.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.recordUpdates != null) {
				for(MetadataService.FlowRecordUpdate fd : sfdcFlow.recordUpdates) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowRecordUpdate', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('record_update');
						addRecordsUpdateInfo(fe, fd, sfdcFlow);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
						if(fd.faultConnector != null && fd.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, fd.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.recordLookups != null) {
				for(MetadataService.FlowRecordLookup fd : sfdcFlow.recordLookups) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowRecordLookup', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('record_lookup');
						addRecordsLookupInfo(fe, fd);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
						if(fd.faultConnector != null && fd.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, fd.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.recordDeletes != null) {
				for(MetadataService.FlowRecordDelete fd : sfdcFlow.recordDeletes) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowRecordDelete', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('record_delete');
						addRecordsDeleteInfo(fe, fd, sfdcFlow);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
						if(fd.faultConnector != null && fd.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, fd.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.screens != null) {
				for(MetadataService.FlowScreen fd : sfdcFlow.screens) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowScreen', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('screen');
						addScreenInfo(fe, fd);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.actionCalls != null) {
				for(MetadataService.FlowActionCall fd : sfdcFlow.actionCalls) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowActionCall', fd.locationX, fd.locationY, fd.description);
						fe.setIcon('action');
						addFlowActionInfo(fe, fd);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
						if(fd.faultConnector != null && fd.faultConnector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.faultConnector.targetReference, PB_ST_VAR_FAUTL, true, fd.faultConnector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.faultConnector.targetReference);
						}
					}
				}
			}

			if(sfdcFlow.recordRollbacks != null) {
				for(MetadataService.FlowRecordRollback fd : sfdcFlow.recordRollbacks) {
					if(fd != null && nextRefferenceName == fd.name) {
						FlowElement fe = new FlowElement(fd.name, fd.label, 'FlowRecordRollback', fd.locationX, fd.locationY, fd.description);
						fe.setIcon(FLOW_ELEMENT_ICON_ROLL_BACK_RECORDS);
						flow.elements.put(fe.name, fe);
						if(fd.connector != null && fd.connector.targetReference != null) {
							flow.addEdge(nextRefferenceName, fd.connector.targetReference, fd.connector.isGoTo);
							getFlowElements(flow,  sfdcFlow, fd.connector.targetReference);
						}
					}
				}
			}
		}
	}

	public class OrchestratedStagesInfo {
		public String label;
		public String name;
		public String description;
		public String conditionLabel;
		public List<StageStepsInfo> stageSteps;
		public String exitActionType;
		public String exitConditionLogic;

		public OrchestratedStagesInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.stageSteps = new List<StageStepsInfo>();
		}
	}

	public class StageStepsInfo {
		public String label;
		public String name;
		public String description;
		public String actionName;
		public String actionType;
		public String conditionValue;
		public String conditionLabel;
		public String assignee;
		public String assigneeType;
		public String exitActionName;
		public String exitActionType;
		public String recordId;

		public StageStepsInfo(String label, String name, String actionName, String actionType, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.actionName = actionName;
			this.actionType = actionType;
		}
	}

	public static void addFlowOrchestratedStagesInfo(FlowElement element, MetadataService.FlowOrchestratedStage flowOrchestratedStage) {
		OrchestratedStagesInfo result = new OrchestratedStagesInfo(flowOrchestratedStage.label, flowOrchestratedStage.name, flowOrchestratedStage.description);

		if(flowOrchestratedStage.stageSteps != null) {
			for(MetadataService.FlowStageStep stageStep : flowOrchestratedStage.stageSteps) {
				StageStepsInfo stageStepInfo = new StageStepsInfo(
					stageStep?.label,
					stageStep?.name,
					stageStep?.actionName,
					stageStep?.actionType,
					stageStep?.description
				);
				if(stageStep?.entryActionType != null && stageStep?.entryActionType == 'evaluationFlow') {
					stageStepInfo.conditionLabel = 'When the specified evaluation flow returns True, the step starts';
					stageStepInfo.conditionValue = stageStep?.entryActionName;
				}
				else if(stageStep?.entryConditions != null && !stageStep?.entryConditions?.isEmpty()) {
					stageStepInfo.conditionLabel = 'When another step is marked Complete, the step starts';
					for(MetadataService.FlowCondition condition : stageStep.entryConditions) {
						if(String.isNotBlank(condition?.leftValueReference)) {
							List<String> parts = condition?.leftValueReference?.split('\\.');
							for(MetadataService.FlowStageStep step : flowOrchestratedStage.stageSteps) {
								if(step.name == parts.get(0)) {
									stageStepInfo.conditionValue = step?.label;
									break;
								}
							}
						}
					}
				}
				else {
					stageStepInfo.conditionLabel = 'When the stage starts, the step starts';
				}

				if(stageStep?.assignees != null && !stageStep?.assignees?.isEmpty()) {
					for(MetadataService.FlowStageStepAssignee stageStepAssignee : stageStep.assignees) {
						stageStepInfo.assigneeType = stageStepAssignee?.assigneeType;
						stageStepInfo.assignee = String.valueOf(getFlowElementReferenceOrValue(stageStepAssignee?.assignee));
					}
				}

				if(stageStep?.inputParameters != null && !stageStep?.inputParameters?.isEmpty()) {
					for(MetadataService.FlowStageStepInputParameter inputParameter : stageStep?.inputParameters) {
						if(inputParameter?.name == 'ActionInput__RecordId') {
							stageStepInfo.recordId = String.valueOf(getFlowElementReferenceOrValue(inputParameter?.value));
						}
					}
				}

				result.stageSteps.add(stageStepInfo);
			}
			result.exitConditionLogic = flowOrchestratedStage.exitConditionLogic;
		}
		element.metadataInfo = result;
	}

	public class FlowRecordDeleteInfo {
		public String label;
		public String name;
		public String description;
		public String objectName;
		public String inputReference;
		public Boolean useTheIDsStored;
		public Boolean specifyConditions;

		public String conditionLogic;
		public String conditionName;
		public String conditionLabel;
		public List<FlowRecordFilterInfo> conditions;

		public FlowRecordDeleteInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.conditions = new List<FlowRecordFilterInfo>();
		}
	}

	public static void addRecordsDeleteInfo(FlowElement element, MetadataService.FlowRecordDelete flowRecordDelete, MetadataService.Flow sfdcFlow) {
		FlowRecordDeleteInfo result = new FlowRecordDeleteInfo(flowRecordDelete.label, flowRecordDelete.name, flowRecordDelete.description);
		result.inputReference = flowRecordDelete.inputReference;
		result.objectName = flowRecordDelete?.object_x == null ? sfdcFlow?.start?.object_x : flowRecordDelete?.object_x;

		if(flowRecordDelete.filters != null) {
			for(MetadataService.FlowRecordFilter filter : flowRecordDelete.filters) {
				result.conditions.add(new FlowRecordFilterInfo(
					filter?.field,
					filter?.operator,
					String.valueOf(getFlowElementReferenceOrValue(filter?.value))
				));
			}
			result.conditionLogic = flowRecordDelete.filterLogic;
			if(result.conditionLogic == null) {
				result.conditionLabel = FLOW_CONDITION_EMPTY_LABEL;
				result.conditionName = FLOW_CONDITION_EMPTY;
			}
			else if(result.conditionLogic == 'and') {
				result.conditionLabel = FLOW_CONDITION_AND_LABEL;
				result.conditionName = FLOW_CONDITION_AND;
			}
			else if(result.conditionLogic == 'or') {
				result.conditionLabel = FLOW_CONDITION_OR_LABEL;
				result.conditionName = FLOW_CONDITION_OR;
			}
			else {
				result.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
				result.conditionName = flowRecordDelete.filterLogic;
				result.conditionLogic = flowRecordDelete.filterLogic;
			}
		}
		result.specifyConditions = (!result.conditions.isEmpty());
		result.useTheIDsStored = !result.specifyConditions;

		element.metadataInfo = result;
	}


	public class FlowSubFlowInfo {
		public String label;
		public String name;
		public String description;
		public String flowName;
		public Boolean manuallyAssignVariables;
		public List<FlowSubflowInputAssignmentInfo> inputAssignments;
		public List<FlowSubflowOutputAssignmentInfo> outputAssignments;

		public FlowSubFlowInfo(String label, String name, String flowName, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.flowName = flowName;
			this.inputAssignments = new List<FlowSubflowInputAssignmentInfo>();
			this.outputAssignments = new List<FlowSubflowOutputAssignmentInfo>();
		}
	}

	public class FlowSubflowInputAssignmentInfo {
		public String name;
		public Object value;

		public FlowSubflowInputAssignmentInfo(String name, Object value) {
			this.name = name;
			this.value = value;
		}
	}

	public class FlowSubflowOutputAssignmentInfo {
		public String name;
		public String assignToReference;

		public FlowSubflowOutputAssignmentInfo(String name, String assignToReference) {
			this.name = name;
			this.assignToReference = assignToReference;
		}
	}

	public class FlowCustomErrorInfo {
		public String label;
		public String name;
		public String description;
		public List<FlowCustomErrorMessage> customErrorMessages;

		public FlowCustomErrorInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.customErrorMessages = new List<FlowCustomErrorMessage>();
		}
	}

	public class FlowCustomErrorMessage {
		public String errorMessage;
        public String fieldSelection;
        public Boolean isFieldError;

		public FlowCustomErrorMessage(String errorMessage, String fieldSelection, Boolean isFieldError) {
			this.errorMessage = errorMessage;
			this.fieldSelection = fieldSelection;
			this.isFieldError = isFieldError;
		}
	}

	public static void addFlowCustomErrorInfo(FlowElement element, MetadataService.FlowCustomError flowCustomError) {
		FlowCustomErrorInfo result = new FlowCustomErrorInfo(flowCustomError.label, flowCustomError.name, flowCustomError.description);
		if(flowCustomError.customErrorMessages != null) {
			for(MetadataService.FlowCustomErrorMessage ia : flowCustomError.customErrorMessages) {
				result.customErrorMessages.add(new FlowCustomErrorMessage(
					ia?.errorMessage,
					ia?.fieldSelection,
					ia?.isFieldError
				));
			}
		}
		element.metadataInfo = result;
	}

	public class FlowSortCollectionInfo {
		public String label;
		public String name;
		public String description;
		public List<FlowCollectionSortOption> sortOptions;
		public Integer limit_x;
		public String elementSubtype;
		public String collectionReference;

		public FlowSortCollectionInfo(String label, String name, String collectionReference, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.collectionReference = collectionReference;
			this.sortOptions = new List<FlowCollectionSortOption>();
		}
	}

	public class FlowCollectionSortOption {
		public String sortField;
		public String sortOrder;
		public Boolean doesPutEmptyStringAndNullFirst;

		public FlowCollectionSortOption(MetadataService.FlowCollectionSortOption sortOption) {
			this.sortField = sortOption.sortField;
			this.sortOrder = sortOption.sortOrder;
			this.doesPutEmptyStringAndNullFirst = sortOption.doesPutEmptyStringAndNullFirst;
		}
	}

	public class FlowFilterCollectionInfo {
		public String label;
		public String name;
		public List<FlowCollectionConditionInfo> conditions;
		// api name of lookup element 
		public String collectionReference;
		public String assignNextValueToReference;
		public String assignNextValueToReferenceDataType;
		public String assignNextValueToReferenceObjectType;
		public Boolean assignNextValueToReferenceIsCollection;
		public String conditionLogic;
		public String conditionName;
		public String conditionLabel;
		public String elementSubtype;

		public FlowFilterCollectionInfo(String label, String name) {
			this.label = label;
			this.name = name;
			this.conditions = new List<FlowCollectionConditionInfo>();
		}
	}

	public class FlowCollectionConditionInfo {
		public String resource;
		public String operator;
		public Object value;

		public FlowCollectionConditionInfo(String resource, String operator, Object value) {
			this.resource = resource;
			this.operator = FlowComparisonOperatorMapping.get(operator);
			this.value = value;
		}
	}

	public static void  addFlowFilterCollectionProcessorInfo(FlowElement element, MetadataService.FlowCollectionProcessor filterCollection, MetadataService.Flow sfdcFlow) {
		FlowFilterCollectionInfo result = new FlowFilterCollectionInfo(filterCollection.label, filterCollection.name);
		result.collectionReference = filterCollection.collectionReference;
		result.assignNextValueToReference = filterCollection.assignNextValueToReference;
		result.elementSubtype = filterCollection.elementSubtype;
		if(String.isNotBlank(result.assignNextValueToReference)) {
			MetadataService.FlowVariable flowVariable = getFlowVariable(result.assignNextValueToReference, sfdcFlow);
			if(flowVariable != null) {
				result.assignNextValueToReferenceDataType = flowVariable.dataType;
				result.assignNextValueToReferenceObjectType = flowVariable.objectType;
				result.assignNextValueToReferenceIsCollection = flowVariable.isCollection;
			}
		}

		if(filterCollection.conditions != null) {
			result.conditionLogic = filterCollection.conditionLogic;
			if(result.conditionLogic == null) {
				result.conditionLabel = FLOW_CONDITION_PAUSE_LABEL;
				result.conditionName = FLOW_CONDITION_EMPTY;
			}
			else if(result.conditionLogic == 'and') {
				result.conditionLabel = FLOW_CONDITION_AND_LABEL;
				result.conditionName = FLOW_CONDITION_AND;
			}
			else if(result.conditionLogic == 'or') {
				result.conditionLabel = FLOW_CONDITION_OR_LABEL;
				result.conditionName = FLOW_CONDITION_OR;
			}
			else {
				result.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
				result.conditionName = filterCollection.conditionLogic;
				result.conditionLogic = filterCollection.conditionLogic;
			}
			
			for(MetadataService.FlowCondition condition : filterCollection.conditions) {
				result.conditions.add(new FlowCollectionConditionInfo(
					condition?.leftValueReference,
					condition?.operator,
					String.valueOf(getFlowElementReferenceOrValue(condition?.rightValue))
				));
			}
		}
		element.metadataInfo = result;
	}

	public static void addFlowSortCollectionProcessorInfo(FlowElement element, MetadataService.FlowCollectionProcessor sortCollection) {
		FlowSortCollectionInfo result = new FlowSortCollectionInfo(sortCollection.label, sortCollection.name, sortCollection.collectionReference, sortCollection.description);
		if(sortCollection.sortOptions != null) {
			for(MetadataService.FlowCollectionSortOption so : sortCollection.sortOptions) {
				result.sortOptions.add(new FlowCollectionSortOption(so));
			}
		}
		result.elementSubtype = sortCollection.elementSubtype;
		if(sortCollection.limit_x != null) {
			result.limit_x = sortCollection.limit_x;
		}
		element.metadataInfo = result;
	}

	public static void addSubFlowInfo(FlowElement element, MetadataService.FlowSubflow subFlow) {
		FlowSubFlowInfo result = new FlowSubFlowInfo(subFlow.label, subFlow.name, subFlow.flowName, subFlow.description);
		if(subFlow.inputAssignments != null) {
			for(MetadataService.FlowSubflowInputAssignment ia : subFlow.inputAssignments) {
				result.inputAssignments.add(new FlowSubflowInputAssignmentInfo(
					ia?.name,
					String.valueOf(getFlowElementReferenceOrValue(ia?.value))
				));
			}
		}
		if(subflow.outputAssignments != null) {
			for(MetadataService.FlowSubflowOutputAssignment ia : subFlow.outputAssignments) {
				result.outputAssignments.add(new FlowSubflowOutputAssignmentInfo(
					ia?.name,
					ia?.assignToReference
				));
			}
			result.manuallyAssignVariables = !result.outputAssignments.isEmpty();
		}
		element.metadataInfo = result;
	}

	public class FlowWaitInfo {
		public String label;
		public String name;
		public String description;
		public List<FlowWaitEventInfo> events;
		public String defaultConnectorLabel;
		public String elementSubtype;
		public String timeZoneId;

		public FlowWaitInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.events = new List<FlowWaitEventInfo>();
		}
	}

	public class FlowWaitEventInfo {

		public String name;
		public String label;
		public String description;
		public String eventType;
		public String conditionLogic;
		public String conditionName;
		public String conditionLabel;

		//WaitDuration
		public Integer offset;
		public String offsetUnit;

		//WaitDate
		public Date resumeDate;
		public String resumeTime;

		public List<FlowWaitEventConditionInfo> conditions;
		public List<FlowWaitEventInputParameterInfo> inputParameters;
		public List<FlowWaitEventOutputParameterInfo> outputParameters;

		public FlowWaitEventInfo(String label, String name, String eventType, String description){
			this.name = name;
			this.label = label;
			this.description = description;
			this.eventType = eventType;
			this.conditions = new List<FlowWaitEventConditionInfo>();
			this.inputParameters = new List<FlowWaitEventInputParameterInfo>();
			this.outputParameters = new List<FlowWaitEventOutputParameterInfo>();
		}
	}

	public class FlowWaitEventConditionInfo {
		public String resource;
		public String operator;
		public Object value;

		public FlowWaitEventConditionInfo(String resource, String operator, Object value) {
			this.resource = resource;
			this.operator = FlowComparisonOperatorMapping.get(operator);
			this.value = value;
		}
	}

	public class FlowWaitEventInputParameterInfo {
		public String name;
		public String value;

		public FlowWaitEventInputParameterInfo(String name, String value) {
			this.name = name;
			this.value = value;
		}
	}

	public class FlowWaitEventOutputParameterInfo {
		public String name;
		public String assignToReference;

		public FlowWaitEventOutputParameterInfo(String name, String assignToReference) {
			this.name = name;
			this.assignToReference = assignToReference;
		}
	}

	public static String getFlowWaitEventLabel(MetadataService.FlowWaitEvent fwe, MetadataService.FlowWait flowWait) {
		String waitEventLabel = fwe?.label;
		// clear default labels (el_0, el_1, el_...)
		if(String.isNotBlank(flowWait?.elementSubtype) && (flowWait?.elementSubtype == 'WaitDuration' || flowWait?.elementSubtype == 'WaitDate')) {
			waitEventLabel = null;
		}
		return waitEventLabel;
	}

	public static void addFlowWaitInfo(FlowElement element, MetadataService.FlowWait flowWait) {
		String label = (String.isNotBlank(flowWait?.elementSubtype)) ? '' : flowWait?.label;
		FlowWaitInfo result = new FlowWaitInfo(label, flowWait.name, flowWait.description);
		result.defaultConnectorLabel = flowWait.defaultConnectorLabel;
		result.elementSubtype = flowWait.elementSubtype;
		result.timeZoneId = flowWait.timeZoneId;
		element.setIcon('wait');

		if(flowWait.waitEvents != null) {
			for(MetadataService.FlowWaitEvent fwe : flowWait.waitEvents) {
				FlowWaitEventInfo fwEventInfo = new FlowWaitEventInfo(getFlowWaitEventLabel(fwe, flowWait), fwe?.name, fwe?.eventType, fwe?.description);

				fwEventInfo.offset = fwe.offset;
				fwEventInfo.offsetUnit = fwe.offsetUnit;

				fwEventInfo.resumeDate = fwe.resumeDate;
				fwEventInfo.resumeTime = fwe.resumeTime;

				if(fwe != null && fwe.conditions != null) {
					fwEventInfo.conditionLogic = fwe.conditionLogic;
					if(fwEventInfo.conditionLogic == null) {
						fwEventInfo.conditionLabel = FLOW_CONDITION_PAUSE_LABEL;
						fwEventInfo.conditionName = FLOW_CONDITION_EMPTY;
					}
					else if(fwEventInfo.conditionLogic == 'and') {
						fwEventInfo.conditionLabel = FLOW_CONDITION_AND_LABEL;
						fwEventInfo.conditionName = FLOW_CONDITION_AND;
					}
					else if(fwEventInfo.conditionLogic == 'or') {
						fwEventInfo.conditionLabel = FLOW_CONDITION_OR_LABEL;
						fwEventInfo.conditionName = FLOW_CONDITION_OR;
					}
					else {
						fwEventInfo.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
						fwEventInfo.conditionName = fwe.conditionLogic;
						fwEventInfo.conditionLogic = fwe.conditionLogic;
					}
					if(fwe.conditions != null) {
						for(MetadataService.FlowCondition condition : fwe.conditions) {
							fwEventInfo.conditions.add(new FlowWaitEventConditionInfo(
								condition?.leftValueReference,
								condition?.operator,
								String.valueOf(getFlowElementReferenceOrValue(condition?.rightValue))
							));
						}
					}
				}

				if(fwe.inputParameters != null) {
					for(MetadataService.FlowWaitEventInputParameter ip : fwe.inputParameters) {
						fwEventInfo.inputParameters.add(new FlowWaitEventInputParameterInfo(
							ip?.name,
							String.valueOf(getFlowElementReferenceOrValue(ip?.value))
						));
					}
				}
				if(fwe.outputParameters != null) {
					for(MetadataService.FlowWaitEventOutputParameter ip : fwe.outputParameters) {
						fwEventInfo.outputParameters.add(new FlowWaitEventOutputParameterInfo(
							ip?.name,
							ip?.assignToReference
						));
					}
				}
				result.events.add(fwEventInfo);
			}
		}

		element.metadataInfo = result;
	}

	public class FlowTransformInfo {
		public String label;
		public String name;
		public String description;
		public String elementSubtype;

		public String apexClass;
        public String dataType;
        public Boolean isCollection;
        public String objectType;
        public Integer scale;
        public FlowTransformValueInfo[] transformValues;

		public FlowTransformInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
		}
	}

	public class FlowTransformValueActionInfo {
		public String name;
		public String outputFieldApiName;
		public String transformType;
		public String value;
		public String formulaDataType;
		public String formulaExpression;

		public FlowTransformValueActionInfo() {}
	}

	public class FlowTransformValueInfo {
		public String transformValueDescription;
		public String transformValueLabel;
		public String transformValueName;
		public List<FlowTransformValueActionInfo> transformValueActions;

		public FlowTransformValueInfo() {
			this.transformValueActions = new List<FlowTransformValueActionInfo>();
		}
	}

	public static void addFlowTransformInfo(FlowElement element, MetadataService.FlowTransform flowTransform) {
		FlowTransformInfo result = new FlowTransformInfo(flowTransform.label, flowTransform.name, flowTransform.description);
		result.elementSubtype = flowTransform.elementSubtype;
		result.description = flowTransform.description;
		result.apexClass = flowTransform.apexClass;
		result.dataType = flowTransform.dataType;
		result.isCollection = flowTransform.isCollection;
		result.objectType = flowTransform.objectType;
		result.transformValues = new List<FlowTransformValueInfo>();

		if(!flowTransform.transformValues?.isEmpty()) {
			for(MetadataService.FlowTransformValue tfv : flowTransform.transformValues) {
				FlowTransformValueInfo tfvi = new FlowTransformValueInfo();
				tfvi.transformValueDescription = tfv.transformValueDescription;
				tfvi.transformValueLabel = tfv.transformValueLabel;
				tfvi.transformValueName = tfv.transformValueName;

				for(MetadataService.FlowTransformValueAction tfva : tfv.transformValueActions) {
					FlowTransformValueActionInfo tfvai = new FlowTransformValueActionInfo();
					tfvai.name = tfva.name;
					tfvai.outputFieldApiName = tfva.outputFieldApiName;
					tfvai.transformType = tfva.transformType;
					tfvai.value = String.valueOf(getFlowElementReferenceOrValue(tfva?.value));
					if(String.isNotBlank(tfva?.value?.formulaDataType)) {
						tfvai.formulaDataType = tfva?.value?.formulaDataType;
					}
					if(String.isNotBlank(tfva?.value?.formulaExpression)) {
						tfvai.formulaExpression = tfva?.value?.formulaExpression;
					}
					tfvi.transformValueActions.add(tfvai);
				}

				result.transformValues.add(tfvi);
			}
		}
		element.metadataInfo = result;
	}
	

	public class FlowLoopInfo {
		public String label;
		public String name;
		public String description;
		public String collectionVariable;
		public String iterationDirection;
		public Boolean firstItemToLastItem;
		public Boolean lastItemToFirstItem;
		public String loopVariable;

		public FlowLoopInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
		}
	}

	public static void addFlowLoopInfo(FlowElement element, MetadataService.FlowLoop flowLoop) {
		FlowLoopInfo result = new FlowLoopInfo(flowLoop.label, flowLoop.name, flowLoop.description);
		result.collectionVariable = flowLoop.collectionReference;
		result.loopVariable = flowLoop.assignNextValueToReference;
		result.iterationDirection = flowLoop.iterationOrder;
		result.firstItemToLastItem = 'Asc' == result.iterationDirection;
		result.lastItemToFirstItem = !result.firstItemToLastItem;
		element.metadataInfo = result;
	}


	public class FlowActionInfo {
		public String label;
		public String name;
		public String description;
		public String actionName;
		public String actionType;
		public List<FlowActionCallInputParameterInfo> assignments;

		public FlowActionInfo(String label, String name, String actionName, String actionType, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.actionName = actionName;
			this.actionType = actionType;
			this.assignments = new List<FlowActionCallInputParameterInfo>();
		}
	}

	public class FlowActionCallInputParameterInfo {
		public String name;
		public Object value;

		public FlowActionCallInputParameterInfo(String name, Object value) {
			this.name = name;
			this.value = value;
		}
	}

	public static void addFlowActionInfo(FlowElement element, MetadataService.FlowActionCall flowAction) {
		FlowActionInfo result = new FlowActionInfo(flowAction.label, flowAction.name, flowAction.actionName, flowAction.actionType, flowAction.description);
		if(flowAction.inputParameters != null) {
			for(MetadataService.FlowActionCallInputParameter ia : flowAction.inputParameters) {
				result.assignments.add(new FlowActionCallInputParameterInfo(
					ia?.name,
					String.valueOf(getFlowElementReferenceOrValue(ia?.value))
				));
			}
		}
		element.metadataInfo = result;
	}



	public class FlowRecordUpdateInfo {
		public String label;
		public String name;
		public String objectName;
		public String description;

		public Boolean specifyConditionsToIdentifyRecords;
		public Boolean useTheIDs;
		public String inputReference;

		public String conditionLogic;
		public String conditionLabel;
		public String conditionName;
		public List<FlowRecordFilterInfo> conditions;
		public List<FlowInputFieldAssignmentInfo> assignments;


		public FlowRecordUpdateInfo(String label, String name, String objectName, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.objectName = objectName;
			this.conditions = new List<FlowRecordFilterInfo>();
			this.assignments = new List<FlowInputFieldAssignmentInfo>();
		}
	}

	public static void addRecordsUpdateInfo(FlowElement element, MetadataService.FlowRecordUpdate flowRecordUpdate, MetadataService.Flow sfdcFlow) {
		FlowRecordUpdateInfo result = new FlowRecordUpdateInfo(flowRecordUpdate.label, flowRecordUpdate.name, flowRecordUpdate?.object_x == null ? sfdcFlow?.start?.object_x : flowRecordUpdate?.object_x, flowRecordUpdate.description);

		if(flowRecordUpdate.filters != null) {
			for(MetadataService.FlowRecordFilter filter : flowRecordUpdate.filters) {
				result.conditions.add(new FlowRecordFilterInfo(
					filter?.field,
					filter?.operator,
					String.valueOf(getFlowElementReferenceOrValue(filter?.value))
				));
			}
			result.conditionLogic = flowRecordUpdate.filterLogic;
			if(result.conditionLogic == null) {
				result.conditionLabel = FLOW_CONDITION_EMPTY_LABEL;
				result.conditionName = FLOW_CONDITION_EMPTY;
			}
			else if(result.conditionLogic == 'and') {
				result.conditionLabel = FLOW_CONDITION_AND_LABEL;
				result.conditionName = FLOW_CONDITION_AND;
			}
			else if(result.conditionLogic == 'or') {
				result.conditionLabel = FLOW_CONDITION_OR_LABEL;
				result.conditionName = FLOW_CONDITION_OR;
			}
			else {
				result.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
				result.conditionName = flowRecordUpdate.filterLogic;
				result.conditionLogic = flowRecordUpdate.filterLogic;
			}
		}

		if(flowRecordUpdate.inputAssignments != null) {
			for(MetadataService.FlowInputFieldAssignment inputFieldAssignment : flowRecordUpdate.inputAssignments) {
				result.assignments.add(new FlowInputFieldAssignmentInfo(
					inputFieldAssignment?.field,
					String.valueOf(getFlowElementReferenceOrValue(inputFieldAssignment?.value))
				));
			}
		}

		result.specifyConditionsToIdentifyRecords = (!result.assignments.isEmpty());
		result.useTheIDs = !result.specifyConditionsToIdentifyRecords;
		result.inputReference = flowRecordUpdate?.inputReference;

		element.metadataInfo = result;
	}

	public class FlowRecordCreateInfo {
		public String label;
		public String name;
		public String objectName;
		public String description;
		public List<FlowInputFieldAssignmentInfo> assignments;

		public Boolean oneRecordsCreate;
		public Boolean multipleRecordsCreate;
		public Boolean useAllValuesFromRecord;
		public Boolean useSeparateResources;
		public Boolean manuallyAssignVariables;

		public String assignRecordIdToReference;
		public String inputReference;


		public FlowRecordCreateInfo(String label, String name, String objectName, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.objectName = objectName;
			this.assignments = new List<FlowInputFieldAssignmentInfo>();
		}
	}

	public class FlowInputFieldAssignmentInfo {
		public String field;
		public Object value;

		public FlowInputFieldAssignmentInfo(String field, Object value) {
			this.field = field;
			this.value = value;
		}
	}

	public static void addRecordsCreateInfo(FlowElement element, MetadataService.FlowRecordCreate flowRecordCreate, MetadataService.Flow sfdcFlow) {
		FlowRecordCreateInfo result = new FlowRecordCreateInfo(flowRecordCreate.label, flowRecordCreate.name, flowRecordCreate?.object_x == null ? sfdcFlow?.start?.object_x : flowRecordCreate?.object_x, flowRecordCreate.description);

		if(flowRecordCreate.inputAssignments != null) {
			for(MetadataService.FlowInputFieldAssignment ia : flowRecordCreate.inputAssignments) {
				result.assignments.add(new FlowInputFieldAssignmentInfo(
					ia?.field,
					String.valueOf(getFlowElementReferenceOrValue(ia?.value))
				));
			}
			if(!flowRecordCreate.inputAssignments.isEmpty()) {
				result.oneRecordsCreate = true;
			}
		}
		if(String.isNotBlank(flowRecordCreate?.assignRecordIdToReference)) {
			result.manuallyAssignVariables = true;
			result.assignRecordIdToReference = flowRecordCreate?.assignRecordIdToReference;
		}
		if(String.isNotBlank(flowRecordCreate?.inputReference)) {
			result.useAllValuesFromRecord = true;
			result.inputReference = flowRecordCreate?.inputReference;

			MetadataService.FlowVariable flowVariable = getFlowVariable(flowRecordCreate?.inputReference, sfdcFlow);
			if(flowVariable != null && String.isBlank(result.objectName) && flowVariable?.objectType != null) {
				result.objectName = flowVariable?.objectType;
			}
			if(flowVariable != null && flowVariable?.isCollection) {
				result.multipleRecordsCreate = true;
			}
			else if(flowVariable != null && !flowVariable?.isCollection) {
				result.oneRecordsCreate = true;
			}
		}

		element.metadataInfo = result;
	}

	public class FlowRecordLookupInfo {
		public String label;
		public String description;
		public String apiName;
		public String objectName;
		public String conditionLogic;
		public String conditionLabel;
		public String conditionName;
		public List<FlowRecordFilterInfo> conditions;
		public List<FlowOutputFieldAssignmentInfo> assignments;
		public String sortOrder;
		public String sortBy;

		public Boolean onlyFirstRecord;
		public Boolean allRecords;
		public Boolean storeAllFields;
		public Boolean chooseFieldsAndLetSalesforceDoTheRest;
		public Boolean chooseFieldsAndAssignVariables;
		public String storeVariable;
		public Boolean storeTogether;
		public Boolean storeSeparateVariables;
		public Boolean noRecordsAreReturned;

		public List<String> queriedFields;

		public  FlowRecordLookupInfo() {
			this.conditions = new List<FlowRecordFilterInfo>();
			this.assignments = new List<FlowOutputFieldAssignmentInfo>();
			this.queriedFields = new List<String>();
		}

	}

	/**
	 * <xsd:simpleType name="FlowRecordFilterOperator">
		<xsd:restriction base="xsd:string">
		<xsd:enumeration value="EqualTo"/>
		<xsd:enumeration value="NotEqualTo"/>
		<xsd:enumeration value="GreaterThan"/>
		<xsd:enumeration value="LessThan"/>
		<xsd:enumeration value="GreaterThanOrEqualTo"/>
		<xsd:enumeration value="LessThanOrEqualTo"/>
		<xsd:enumeration value="StartsWith"/>
		<xsd:enumeration value="EndsWith"/>
		<xsd:enumeration value="Contains"/>
		<xsd:enumeration value="IsNull"/>
		<xsd:enumeration value="IsChanged"/>
		<xsd:enumeration value="In"/>
		<xsd:enumeration value="NotIn"/>
		</xsd:restriction>
		</xsd:simpleType>
	 */
	public static final Map<String, String> FlowRecordFilterOperatorMapping = new Map<String, String>{
		'EqualTo' => 'Equals',
		'NotEqualTo' => 'Does Not Equal',
		'GreaterThan' => 'Greater Than',
		'LessThan' => 'Less Than',
		'GreaterThanOrEqualTo' => 'Greater Than or Equal',
		'LessThanOrEqualTo' => 'Less Than or Equal',
		'StartsWith' => 'Starts With',
		'EndsWith' => 'Ends With',
		'Contains' => 'Contains',
		'IsNull' => 'Is Null',
		'IsChanged' => 'Is Changed',
		'In' => 'In',
		'NotIn' => 'Not In'
	};

	public class FlowRecordFilterInfo {
		public String field;
		public String operator;
		public Object value;

		public FlowRecordFilterInfo(String field, String operator, Object value){
			this.field = field;
			this.operator = FlowRecordFilterOperatorMapping.get(operator);
			this.value = value;
		}
	}

	public class FlowOutputFieldAssignmentInfo {
		public String field;
		public String variable;

		public FlowOutputFieldAssignmentInfo(String field, String variable) {
			this.field = field;
			this.variable = variable;
		}
	}

	public static void addRecordsLookupInfo(FlowElement element, MetadataService.FlowRecordLookup flowRecordLookup) {
		FlowRecordLookupInfo result = new FlowRecordLookupInfo();
		result.label = flowRecordLookup.label;
		result.description = flowRecordLookup.description;
		result.apiName = flowRecordLookup.name;
		result.objectName = flowRecordLookup.object_x;

		result.allRecords = flowRecordLookup.getFirstRecordOnly == false; 
  		result.onlyFirstRecord = !result.allRecords;
		result.storeAllFields = true;



		if(String.isNotBlank(flowRecordLookup.outputReference)) {
			result.storeVariable = flowRecordLookup.outputReference;
			result.noRecordsAreReturned = flowRecordLookup.assignNullValuesIfNoRecordsFound;

			if(flowRecordLookup.queriedFields != null) {
				for(String qField : flowRecordLookup.queriedFields) {
					result.queriedFields.add(qField);
				}
				result.chooseFieldsAndAssignVariables = !flowRecordLookup.queriedFields.isEmpty();
				result.storeAllFields = !result.chooseFieldsAndAssignVariables;
				result.storeTogether = true;
			}
		}
		else {
			if(flowRecordLookup.queriedFields != null) {
				for(String qField : flowRecordLookup.queriedFields) {
					result.queriedFields.add(qField);
				}
				result.chooseFieldsAndLetSalesforceDoTheRest = !flowRecordLookup.queriedFields.isEmpty();
				result.storeAllFields = !result.chooseFieldsAndLetSalesforceDoTheRest;
			}
		}

		if(flowRecordLookup.filters != null) {
			for(MetadataService.FlowRecordFilter filter : flowRecordLookup.filters) {
				result.conditions.add(new FlowRecordFilterInfo(
					filter?.field,
					filter?.operator,
					String.valueOf(getFlowElementReferenceOrValue(filter?.value))
				));
			}

			result.conditionLogic = flowRecordLookup.filterLogic;
			if(result.conditionLogic == null) {
				result.conditionLabel = FLOW_CONDITION_EMPTY_LABEL;
				result.conditionName = FLOW_CONDITION_EMPTY;
			}
			else if(result.conditionLogic == 'and') {
				result.conditionLabel = FLOW_CONDITION_AND_LABEL;
				result.conditionName = FLOW_CONDITION_AND;
			}
			else if(result.conditionLogic == 'or') {
				result.conditionLabel = FLOW_CONDITION_OR_LABEL;
				result.conditionName = FLOW_CONDITION_OR;
			}
			else {
				result.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
				result.conditionName = flowRecordLookup.filterLogic;
				result.conditionLogic = flowRecordLookup.filterLogic;
			}
		}
		result.sortOrder = flowRecordLookup.sortOrder;
		result.sortBy = flowRecordLookup.sortField;

		if(flowRecordLookup.outputAssignments != null) {
			for(MetadataService.FlowOutputFieldAssignment outputFieldAssignment : flowRecordLookup.outputAssignments) {
				result.assignments.add(new FlowOutputFieldAssignmentInfo(
					outputFieldAssignment?.field,
					outputFieldAssignment?.assignToReference
				));
			}

			result.chooseFieldsAndAssignVariables = !flowRecordLookup.outputAssignments.isEmpty();
			result.storeAllFields = !result.chooseFieldsAndAssignVariables;
			result.storeSeparateVariables = true;
		}

		element.metadataInfo = result;
	}

	public class FlowDecisionInfo {
		public String name;
		public String label;
		public String description;
		public List<FlowDecisionOutcomeInfo> outcomes;

		public FlowDecisionInfo(){
			this.outcomes = new List<FlowDecisionOutcomeInfo>();
		}

	}

	public class FlowDecisionOutcomeInfo {
		public String label;
		public String name;
		public String description;
		public String condition;
		public String conditionLogic;
		public String conditionName;
		public String conditionLabel;
		public List<FlowConditionInfo> conditions;

		public FlowDecisionOutcomeInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
			this.conditions = new List<FlowConditionInfo>();
		}
	}

	/**
	 * <xsd:simpleType name="FlowComparisonOperator">
		<xsd:restriction base="xsd:string">
		<xsd:enumeration value="None"/>
		<xsd:enumeration value="EqualTo"/>
		<xsd:enumeration value="NotEqualTo"/>
		<xsd:enumeration value="GreaterThan"/>
		<xsd:enumeration value="LessThan"/>
		<xsd:enumeration value="GreaterThanOrEqualTo"/>
		<xsd:enumeration value="LessThanOrEqualTo"/>
		<xsd:enumeration value="StartsWith"/>
		<xsd:enumeration value="EndsWith"/>
		<xsd:enumeration value="Contains"/>
		<xsd:enumeration value="IsNull"/>
		<xsd:enumeration value="IsChanged"/>
		<xsd:enumeration value="WasSet"/>
		<xsd:enumeration value="WasSelected"/>
		<xsd:enumeration value="WasVisited"/>
		<xsd:enumeration value="In"/>
		<xsd:enumeration value="NotIn"/>
		<xsd:enumeration value="IsBlank"/>
		<xsd:enumeration value="IsEmpty"/>
		</xsd:restriction>
		</xsd:simpleType>
	 */
	public static final Map<String, String> FlowComparisonOperatorMapping = new Map<String, String>{
		'None' => '',
		'EqualTo' => 'Equals',
		'NotEqualTo' => 'Does Not Equal',
		'GreaterThan' => 'Greater Than',
		'LessThan' => 'Less Than',
		'GreaterThanOrEqualTo' => 'Greater Than or Equal',
		'LessThanOrEqualTo' => 'Less Than or Equal',
		'StartsWith' => 'Starts With',
		'EndsWith' => 'Ends With',
		'Contains' => 'Contains',
		'IsNull' => 'Is Null',
		'IsChanged' => 'Is Changed',
		'WasSet' => 'Was Set',
		'WasSelected' => 'Was Selected',
		'WasVisited' => 'Was Visited',
		'In' => 'In',
		'NotIn' => 'Not In',
		'IsBlank' => 'Is Blank',
		'IsEmpty' => 'Is Empty'
	};

	public class FlowConditionInfo {
		public String resource;
		public String operator;
		public Object value;

		public FlowConditionInfo(String resource, String operator, Object value) {
			this.resource = resource;
			this.operator = FlowComparisonOperatorMapping.get(operator);
			this.value = value;
		}
	}



	public static void addDecisionInfo(FlowElement element, MetadataService.FlowDecision flowDecision) {
		FlowDecisionInfo result = new FlowDecisionInfo();
		result.name = flowDecision.name;
		result.label = flowDecision.label;
		result.description = flowDecision.description;

		if(flowDecision.rules != null) {
			for(MetadataService.FlowRule rule : flowDecision.rules) {
				FlowDecisionOutcomeInfo fdo = new FlowDecisionOutcomeInfo(rule?.label, rule?.name, rule?.description);

				fdo.condition = rule?.conditionLogic;
				if(rule.conditionLogic == null) {
					fdo.conditionLabel = FLOW_CONDITION_EMPTY_LABEL;
					fdo.conditionName = FLOW_CONDITION_EMPTY;
				}
				else if(rule.conditionLogic == 'and') {
					fdo.conditionLabel = FLOW_CONDITION_AND_LABEL;
					fdo.conditionName = FLOW_CONDITION_AND;
				}
				else if(rule.conditionLogic == 'or') {
					fdo.conditionLabel = FLOW_CONDITION_OR_LABEL;
					fdo.conditionName = FLOW_CONDITION_OR;
				}
				else {
					fdo.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
					fdo.conditionName = rule.conditionLogic;
					fdo.conditionLogic = rule.conditionLogic;
				}

				if(rule.conditions != null) {
					for(MetadataService.FlowCondition fc : rule.conditions) {
						FlowConditionInfo fci = new FlowConditionInfo(
							fc?.leftValueReference,
							fc?.operator,
							String.valueOf(getFlowElementReferenceOrValue(fc?.rightValue))
						);
						fdo.conditions.add(fci);
					}
				}

				result.outcomes.add(fdo);
			}
		}

		element.metadataInfo = result;
	}

	public class FlowScreenInfo {
		public String label;
		public String name;
		public String description;
		public Boolean showHeader;
		public Boolean showFooter;
		public Boolean nextOrFinish;
		public Boolean previous;
		public Boolean pause;
		public String helpText;

		public FlowScreenInfo(String label, String name, String description) {
			this.label = label;
			this.name = name;
			this.description = description;
		}
	}

	public static void addScreenInfo(FlowElement element, MetadataService.FlowScreen flowScreen) {
		FlowScreenInfo result = new FlowScreenInfo(flowScreen.label, flowScreen.name, flowScreen.description);
		result.showHeader = flowScreen.showHeader;
		result.showFooter = flowScreen.showFooter;
		result.nextOrFinish = flowScreen.allowFinish;
		result.previous = flowScreen.allowBack;
		result.pause = flowScreen.allowPause;
		result.helpText = flowScreen.helpText;

		element.metadataInfo = result;
	}

	public class FlowAssignmentInfo {
		public String label;
		public String name;
		public String descirption;
		public List<FlowAssignmentsItemInfo> assignments;

		public FlowAssignmentInfo(String label, String name, String descirption) {
			this.label = label;
			this.name = name;
			this.descirption = descirption;
			this.assignments = new List<FlowAssignmentsItemInfo>();
		}
	}

	/**
	 * <xsd:simpleType name="FlowAssignmentOperator">
		<xsd:restriction base="xsd:string">
		<xsd:enumeration value="None"/>
		<xsd:enumeration value="Assign"/>
		<xsd:enumeration value="Add"/>
		<xsd:enumeration value="Subtract"/>
		<xsd:enumeration value="AddItem"/>
		<xsd:enumeration value="RemoveFirst"/>
		<xsd:enumeration value="RemoveBeforeFirst"/>
		<xsd:enumeration value="RemoveAfterFirst"/>
		<xsd:enumeration value="RemoveAll"/>
		<xsd:enumeration value="AddAtStart"/>
		<xsd:enumeration value="RemoveUncommon"/>
		<xsd:enumeration value="AssignCount"/>
		<xsd:enumeration value="RemovePosition"/>
		</xsd:restriction>
		</xsd:simpleType>
	 */
	public static final Map<String, String> FlowAssignmentOperatorMapping = new Map<String, String>{
		'None' => '',
		'Assign' => 'Equals',
		'Add' => 'Add',
		'Subtract' => 'Subtract',
		'AddItem' => 'Add Item',
		'RemoveFirst' => 'Remove First',
		'RemoveBeforeFirst' => 'Remove Before First',
		'RemoveAfterFirst' => 'Remove After First',
		'RemoveAll' => 'Remove All',
		'AddAtStart' => 'Add At Start',
		'RemoveUncommon' => 'Remove Uncommon',
		'AssignCount' => 'Equals Count',
		'RemovePosition' => 'Remove Position'
	};

	public class FlowAssignmentsItemInfo {

		public String variable;
		public String operator;
		public Object value;

		public FlowAssignmentsItemInfo(String variable, String operator, Object value) {
			this.variable = variable;
			this.operator = FlowAssignmentOperatorMapping.get(operator);
			this.value = value;
		}
	}

	public static void addAssignmentInfo(FlowElement element, MetadataService.FlowAssignment flowAssignment) {
		FlowAssignmentInfo result = new FlowAssignmentInfo(flowAssignment.label, flowAssignment.name, flowAssignment.description);

		if(flowAssignment.assignmentItems != null) {
			for(MetadataService.FlowAssignmentItem fai : flowAssignment.assignmentItems) {
				result.assignments.add(new FlowAssignmentsItemInfo(
					fai?.assignToReference,
					fai?.operator,
					String.valueOf(getFlowElementReferenceOrValue(fai?.value))
				));
			}
		}
		element.metadataInfo = result;
	}

	public class Flow {
		public String name;
		public String label;
		public String processType;
		public String description;
		public FlowStart start;
		public Map<String, FlowElement> elements;
		public Map<String, Set<FlowEdge>> edges;
		public Map<String, Object> context;
		public List<StackTraceParser.StackTraceParseResult> apexStackTraceParseResults;
		public String errorMessage;
		public String errorMessageHtml;
		public String orchestratorFailedFlowApiName;
		public List<Flow> subflows;
		public List<FlowVariable> variables;

		public Flow() {
			this.elements = new Map<String, FlowElement>();
			this.edges = new Map<String, Set<FlowEdge>>();
			this.apexStackTraceParseResults = new List<StackTraceParser.StackTraceParseResult>();
			this.context = new Map<String, Object>();
			this.subflows = new List<Flow>();
			this.variables = new List<FlowVariable>();
		}

		public void addDefaultEdge(String startPath, String endPath, String edgeLabel, Boolean isGoTo) {
			addEdge(startPath, endPath, edgeLabel, null, false, true, isGoTo);
		}

		public void addDefaultEdge(String startPath, String endPath, Boolean isGoTo) {
			addEdge(startPath, endPath, null, null, false, true, isGoTo);
		}

		public void addEdge(String startPath, String endPath, Boolean isGoTo) {
			addEdge(startPath, endPath, null, false, isGoTo);
		}

		public void addEdge(String startPath, String endPath, String edgeLabel, String edgeName, Boolean isFault, Boolean isGoTo) {
			addEdge(startPath, endPath, edgeLabel, edgeName, isFault, false, isGoTo);
		}

		public void addEdge(String startPath, String endPath, String edgeLabel, String edgeName, Boolean isFault, Boolean isDefault, Boolean isGoTo) {
			Set<FlowEdge> edges = this.edges.get(startPath) != null ? this.edges.get(startPath) : new Set<FlowEdge>();
			FlowEdge fe = new FlowEdge(endPath, edgeLabel, edgeName, isFault, isDefault, isGoTo);
			edges.add(fe);
			this.edges.put(startPath, edges);
		}

		public void addEdge(String startPath, String endPath, String edgeLabel, Boolean isGoTo) {
			addEdge(startPath, endPath, edgeLabel, null, false, isGoTo);
		}

		public void addEdge(String startPath, String endPath, String edgeLabel, String edgeName, Boolean isGoTo) {
			addEdge(startPath, endPath, edgeLabel, edgeName, false, isGoTo);
		}

		public void addEdge(String startPath, String endPath, String edgeLabel, Boolean isFault, Boolean isGoTo) {
			addEdge(startPath, endPath, edgeLabel, null, isFault, false, isGoTo);
		}

	}

	public class FlowVariable {
		public String name;
		public String description;
		public String apexClass;
		public Boolean isCollection;
		public Boolean isInput;
		public Boolean isOutput;
		public String objectType;
		public String dataType;

		public FlowVariable(){}
	}

	public class FlowEdge {
		public String name;
		public String label;
		public String target;
		public Boolean fault;
		public Boolean isDefault;
		public Boolean isGoTo;
		public List<Integer> indexes;

		public FlowEdge(String target){
			this(target, null);
		}

		public FlowEdge(String target, String label){
			this(target, label, label, false, false, false);
		}

		public FlowEdge(String target, String label, String name, Boolean isFault, Boolean isDefault, Boolean isGoTo) {
			this.target = target;
			this.label = label;
			this.name = name;
			this.indexes = new List<Integer>();
			this.fault = isFault;
			this.isDefault = isDefault;
			this.isGoTo = isGoTo;
			this.label = (this.label == null && isDefault) ? 'Default Path' : this.label;
		}

		public void addIndex(Integer index) {
			this.indexes.add(index);
		}
	}

	public class FlowScheduledPath {
		public String name;
		public String label;
		public Integer offsetNumber;
		public String offsetUnit;
		public String timeSource;
		public String targetReference;
		public Integer maxBatchSize;
		public String recordField;
		public String pathType;

		public FlowScheduledPath() {}
	}

	public class FlowStart {
		public String startType;
		public String objectType;

		public Location location;
		public String startRefference;

		public Boolean aRecordIsCreated;
		public Boolean aRecordIsUpdated;
		public Boolean aRecordIsCreatedOrUpdated;
		public Boolean aRecordIsDeleted;
		public Boolean runFlowBeforeTheRecordIsSaved;
		public Boolean runFlowAfterTheRecordIsSaved;
		public Boolean runTheFlowEveryTime;
		public Boolean runTheFlowOnlyUpdate;

		public String recordTriggerType;
		public String triggerType;
		public String conditionLogic;
		public String conditionLabel;
		public String conditionName;
		public List<FlowRecordFilterInfo> conditions;

		public String scheduleFrequency;
		public String scheduleStartDate;
		public String scheduleStartTime;

		public FlowScheduledPath[] scheduledPaths;
		public String canvasMode;
		public String flowRunAsUser;
		public String filterFormula;

		public FlowStart(String processType, MetadataService.Flow sfdcFlow) {
			this.triggerType = sfdcFlow?.start?.triggerType;
			this.location = new Location(sfdcFlow?.start?.locationX, sfdcFlow?.start?.locationY);
			this.objectType = sfdcFlow?.start?.object_x;
			if(sfdcFlow?.start?.connector != null && sfdcFlow?.start?.connector?.targetReference != null) {
				this.startRefference = sfdcFlow?.start?.connector?.targetReference;
			}
			// converted Processbuilder to Flow
			if(sfdcFlow?.startElementReference != null) {
				this.startRefference = sfdcFlow.startElementReference;
			}

			this.runTheFlowOnlyUpdate = (sfdcFlow?.start?.doesRequireRecordChangedToMeetCriteria != null && sfdcFlow?.start?.doesRequireRecordChangedToMeetCriteria);
			this.runTheFlowEveryTime = !this.runTheFlowOnlyUpdate;
			this.recordTriggerType = sfdcFlow?.start?.recordTriggerType;
			this.flowRunAsUser = sfdcFlow?.start?.flowRunAsUser;
			this.aRecordIsCreated = (this.recordTriggerType == 'Create');
			this.aRecordIsUpdated = (this.recordTriggerType == 'Update');
			this.aRecordIsCreatedOrUpdated = (this.recordTriggerType == 'CreateAndUpdate');
			this.aRecordIsDeleted = (this.recordTriggerType == 'Delete');
			this.runFlowBeforeTheRecordIsSaved = (this.triggerType == 'RecordBeforeSave');
			this.runFlowAfterTheRecordIsSaved = (this.triggerType == 'RecordAfterSave');

			Object canvasModeObject = getProcessMetadataValue('CanvasMode', sfdcFlow?.processMetadataValues);
			this.canvasMode = canvasModeObject != null ? String.valueOf(canvasModeObject) : null;

			if(sfdcFlow?.start?.filters != null) {
				this.conditions = new List<FlowRecordFilterInfo>();
				for(MetadataService.FlowRecordFilter filter : sfdcFlow.start.filters) {
					this.conditions.add(new FlowRecordFilterInfo(
						filter?.field,
						filter?.operator,
						String.valueOf(getFlowElementReferenceOrValue(filter?.value))
					));
				}
				this.conditionLogic = sfdcFlow?.start?.filterLogic;
				if(this.conditionLogic == null) {
					this.conditionLabel = FLOW_CONDITION_EMPTY_LABEL;
					this.conditionName = FLOW_CONDITION_EMPTY;
				}
				else if(this.conditionLogic == 'and') {
					this.conditionLabel = FLOW_CONDITION_AND_LABEL;
					this.conditionName = FLOW_CONDITION_AND;
				}
				else if(this.conditionLogic == 'or') {
					this.conditionLabel = FLOW_CONDITION_OR_LABEL;
					this.conditionName = FLOW_CONDITION_OR;
				}
				else {
					this.conditionLabel = FLOW_CONDITION_CUSTOM_LABEL;
					this.conditionName = sfdcFlow.start.filterLogic;
					this.conditionLogic = sfdcFlow.start.filterLogic;
				}
			} else if (sfdcFlow?.start?.filterFormula != null){
				this.filterFormula = sfdcFlow?.start?.filterFormula;
				this.conditionLabel = FLOW_CONDITION_FORMULA_LABEL;
				this.conditionName = FLOW_CONDITION_FORMULA;
			}

			if(sfdcFlow?.start?.schedule != null) {
				this.scheduleFrequency = sfdcFlow.start.schedule?.frequency;
				this.scheduleStartDate = sfdcFlow.start.schedule?.startDate;
				this.scheduleStartTime = sfdcFlow.start.schedule?.startTime;
			}

			if(sfdcFlow?.start?.scheduledPaths != null) {
				this.scheduledPaths = new List<FlowScheduledPath>();
				for(MetadataService.FlowScheduledPath fsp : sfdcFlow.start.scheduledPaths) {
					FlowScheduledPath sp = new FlowScheduledPath();
					sp.name = fsp?.name;
					sp.label = fsp?.label;
					sp.offsetNumber = fsp?.offsetNumber;
					sp.offsetUnit = fsp?.offsetUnit;
					sp.timeSource = fsp?.timeSource;
					sp.recordField = fsp?.recordField;
					sp.maxBatchSize = fsp?.maxBatchSize;
					sp.pathType = fsp?.pathType;
					sp.targetReference = fsp?.connector?.targetReference;
					this.scheduledPaths.add(sp);
				}
			}
		}
	}

	public class Location {
		public Integer X;
		public Integer Y;

		public Location(Integer x, Integer y) {
			this.X = x;
			this.Y = y;
		}
	}

	public class FlowElement {
		public String name;
		public String label;
		public String description;
		public String actionType;
		public Boolean executed;
		public Map<String, Object> context;
		public String icon;
		public Location location;

		public Object metadataInfo;

		public FlowElement(String name, String label, String actionType, Integer locationX, Integer locationY, String description) {
			this.name = name;
			this.label = label;
			this.description = description;
			this.actionType = actionType;
			this.executed = false;
			this.context = new Map<String, Object>();
			this.location = new Location(locationX, locationY);
		}

		public void setIcon(String icon) {
			this.icon = icon;
		}

	}

	public class FlowAiMeta {
		public String errorNode;
		public List<String> nodesAfterError;
	}

	public class RawFlowData {
		public Map<String, List<RawEdge>> edges;
	}

	public class RawEdge {
		public String target;
		public List<Integer> indexes;
	}

	public static FlowAiMeta getFlowAiMeta(String stacktrace) {
		RawFlowData flowData = (RawFlowData) JSON.deserialize(stacktrace, RawFlowData.class);
		FlowAiMeta result = new FlowAiMeta();
		String errorNode;
		List<String> nodesAfterError = new List<String>();

		if (flowData.edges != null) {
			errorNode = getErrorNode(flowData.edges);
		}

		if (errorNode != null) {
			List<String> queue = getElementsQueue(flowData.edges, errorNode);
			for (String n : queue) {
				if (n != errorNode) {
					nodesAfterError.add(n);
				}
			}
		}

		result.errorNode = errorNode;
		result.nodesAfterError = nodesAfterError;

		return result;
	}

	public static String getErrorNode(Map<String, List<RawEdge>> edges) {
		String resultTarget = null;
		Integer maxIndex = -1;

		for (String key : edges.keySet()) {
			List<RawEdge> edgeList = edges.get(key);
			for (RawEdge edge : edgeList) {
				if (edge.indexes != null && !edge.indexes.isEmpty()) {
					for (Integer index : edge.indexes) {
						if (index > maxIndex) {
							maxIndex = index;
							resultTarget = edge.target;
						}
					}
				}
			}
		}
		return resultTarget;
	}

	public static List<String> getElementsQueue(Map<String, List<RawEdge>> edges, String startNode) {
		Map<String, List<String>> queueMap = new Map<String, List<String>>();
		Set<String> visited = new Set<String>();

		for (String edge : edges.keySet()) {
			List<String> targets = new List<String>();
			for (RawEdge e : edges.get(edge)) {
				targets.add(e.target);
			}
			queueMap.put(edge, targets);
		}
		return getElementsFromNode(startNode, queueMap, visited);
	}

	public static List<String> getElementsFromNode(String node, Map<String, List<String>> queueMap, Set<String> visited) {
		if (visited.contains(node)) {
			return new List<String>();
		}
		List<String> result = new List<String>();
		result.add(node);
		visited.add(node);
		if (queueMap.containsKey(node)) {
			for (String target : queueMap.get(node)) {
				result.addAll(getElementsFromNode(target, queueMap, visited));
			}
		}
		return result;
	}
	
}