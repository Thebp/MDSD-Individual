package dk.sdu.mmmi.mdsd.iot_dsl.ui

import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.Diagnostician
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.ComponentType
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.PropertyUse
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.System
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Board
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Component
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.ActuatorType

class IoTDSLEObjectHoverProvider extends DefaultEObjectHoverProvider{
	
	override protected getHoverInfoAsHtml(EObject o) {
		if(o instanceof ComponentType && o.programHasNoError) {
			return	'''
					<p>
					�IF o instanceof ActuatorType�
					ActuatorType
					�ELSE�
					SensorType
					�ENDIF�
					<b>�(o as ComponentType).name�</b>
					�FOR b : o.getContainerOfType(System).boards�
					�b.getComponentsOfType(o as ComponentType)�
					�ENDFOR�
					</p>
					'''
		}
		super.getHoverInfoAsHtml(o)
	}
	
	def getComponentsOfType(Board board, ComponentType type) {
		return	'''
				�FOR c : board.elements.filter(Component)�
				�IF c.type == type�
				<br/>�board.name�.�c.name�
				�ENDIF�
				�ENDFOR�
				'''
	}
	
	
	def programHasNoError(EObject o) {
		Diagnostician.INSTANCE.validate(o.rootContainer).children.empty
	}
	
}