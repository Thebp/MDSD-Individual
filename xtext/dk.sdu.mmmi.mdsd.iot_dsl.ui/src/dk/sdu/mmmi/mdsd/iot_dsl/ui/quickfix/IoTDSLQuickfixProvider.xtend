/*
 * generated by Xtext 2.16.0
 */
package dk.sdu.mmmi.mdsd.iot_dsl.ui.quickfix

import org.eclipse.xtext.ui.editor.quickfix.DefaultQuickfixProvider
import org.eclipse.xtext.ui.editor.quickfix.Fix
import dk.sdu.mmmi.mdsd.iot_dsl.validation.IoTDSLValidator
import org.eclipse.xtext.validation.Issue
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor

/**
 * Custom quickfixes.
 *
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#quick-fixes
 */
class IoTDSLQuickfixProvider extends DefaultQuickfixProvider {

	@Fix(IoTDSLValidator.INVALID_PORT)
	def changeMqttPort(Issue issue, IssueResolutionAcceptor acceptor){
		acceptor.accept(issue, 'Change MQTT port to standard', 'Change the MQTT port to the standard 1883.',"")[
			context |
			val xtextDocument = context.xtextDocument
			val portNumber = xtextDocument.get(issue.offset, issue.length)
			xtextDocument.replace(issue.offset, issue.length, portNumber.replace(portNumber, "1883"))
		]
	}

	@Fix(IoTDSLValidator.INVALID_RATE)
	def changeRate(Issue issue, IssueResolutionAcceptor acceptor){
		acceptor.accept(issue, 'Change the max rate', 'Change the max rate to match the component rate', "")[
			context |
			val xtextDocument = context.xtextDocument
			val rate = xtextDocument.get(issue.offset, issue.length)
			xtextDocument.replace(issue.offset, issue.length, rate.replace(rate, 'maximum every ' + issue.data.head))
		]
	}
}
