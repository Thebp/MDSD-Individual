package dk.sdu.mmmi.mdsd.iot_dsl.generator

import org.eclipse.xtext.generator.IGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import java.util.Map
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Loop
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.System
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Board
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Component
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.ComponentType
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Statement
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Expose
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Mqtt
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.SensorType
import java.util.Set
import dk.sdu.mmmi.mdsd.iot_dsl.ioTDSL.Property

class ServerGenerator implements IGenerator{
	
	var Map<Loop, String> loopNames
	
	override doGenerate(Resource resource, IFileSystemAccess fsa) {
		val system = resource.allContents.filter(System).next
		loopNames = newLinkedHashMap
		system.logic.filter(Loop).forEach[loop, i| loopNames.put(loop, "loop"+i)]
		fsa.generateFile('server/main.go', system.generateServer)
	}
	
	def CharSequence generateServer(System system) '''
			package main
			
			import (
				"fmt"
				"net/http"
				"strconv"
				"time"
				
				mqtt "github.com/eclipse/paho.mqtt.golang"
				"github.com/gorilla/mux"
			)
			
			type server struct {
				client mqtt.Client
				«FOR board : system.boards»
				«board.name» *board_«board.name»
				«ENDFOR»
			}
			
			func (s *server) send_message(topic string, payload interface{}) {
				token := s.client.Publish(topic, 0, false, payload)
				token.Wait()
			}
			
			«FOR loop : system.logic.filter(Loop)»
			«loop.generateLoopFunction»
			«ENDFOR»
			
			«FOR expose : system.expose»
			«expose.generateExpose»
			«ENDFOR»
			
			«FOR board : system.boards»
			«board.generateBoardType»
			«ENDFOR»
			
			«FOR componentType : system.usedComponentTypes»
			«componentType.generateComponentType»
			«ENDFOR»
			
			func main() {
				«system.mqtt.generateMQTT»
				
				server := server{
					mqtt_client,
					«FOR board : system.boards»
					&board_«board.name»{«FOR component : board.elements.filter(Component)»&«component.type.name»{},«ENDFOR»},
					«ENDFOR»
				}
				
				«FOR board : system.boards»
					«FOR component : board.elements.filter(Component)»
						«IF component.type instanceof SensorType»
							«FOR property : component.type.properties»
							«generatePropertySubscription(board, component, property)»
							«ENDFOR»
						«ENDIF»
					«ENDFOR»
				«ENDFOR»
				
				r := mux.NewRouter()
				«FOR expose : system.expose»
				r.HandleFunc("/«expose.name»", server.«expose.name»)
				«ENDFOR»
				
				«FOR loop : system.logic.filter(Loop)»
				go server.«loopNames.get(loop)»()
				«ENDFOR»
				
				http.ListenAndServe(":«system.server.port»", r)
			}
		'''
		
		def CharSequence generatePropertySubscription(Board board, Component component, Property property) '''
			mqtt_client.Subscribe("«board.name»/«component.name»/«property.name»", 0, func(client mqtt.Client, msg mqtt.Message) {
				«IF property.type.equals("string")»
				value := string(msg.Payload())
				server.«board.name».«component.name».«property.name» = value
				«ELSE»
				value, err := «property.generateStringConversion»
				if err != nil {
					fmt.Println(fmt.Errorf("Error on topic %v: %v", msg.Topic(), err))
				} else {
					server.«board.name».«component.name».«property.name» = value
				}
				«ENDIF»
				
			})
		'''
		
		def CharSequence generateStringConversion(Property property) {
			switch property.type {
				case "integer": "strconv.ParseInt(string(msg.Payload()), 10, 64)"
				case "float": "strconv.ParseFloat(string(msg.Payload()), 64)"
				case "boolean": "strconv.ParseBool(string(msg.Payload()))"
			}
		}
		
		def CharSequence generateMQTT(Mqtt mqtt) '''
			opts := mqtt.NewClientOptions()
			opts.AddBroker("«mqtt.host»:«mqtt.port»")
			opts.SetClientID("server")
			opts.SetUsername("«mqtt.user»")
			opts.SetPassword("«mqtt.pass»")
			
			mqtt_client := mqtt.NewClient(opts)
			if token := mqtt_client.Connect(); token.Wait() && token.Error() != nil {
				panic(token.Error())
			}
		'''
		
		def CharSequence generateLoopFunction(Loop loop) '''
			func (s *server) «loopNames.get(loop)»() {
				for _ = range time.Tick(«loop.time» * «loop.timeunit.generateTimeUnit») {
					«FOR statement : loop.statements»
					«statement.generateStatement»
					«ENDFOR»
				}
			}
		'''
		
		def CharSequence generateTimeUnit(String timeUnit) {
			switch timeUnit {
				case "hours": "time.Hour"
				case "minutes": "time.Minute"
				case "seconds": "time.Second"
			}
		}
		
		def CharSequence generateStatement(Statement statement) '''
			// Insert statement here
		'''
		
		def CharSequence generateExpose(Expose expose) '''
			func (s *server) «expose.name»(w http.ResponseWriter, r *http.Request) {
				«FOR statement : expose.statements»
				«statement.generateStatement»
				«ENDFOR»
			}
		'''
		
		def CharSequence generateBoardType(Board board) '''
			type board_«board.name» struct {
				«FOR component : board.elements.filter(Component)»
				«component.name» *«component.type.name»
				«ENDFOR»
			}
		'''
		
		def CharSequence generateComponentType(ComponentType type) '''
			type «type.name» struct {
				«FOR property : type.properties»
				«property.name» «property.type.generatePropertyType»
				«ENDFOR»
			}
		'''
		
		def CharSequence generatePropertyType(String type) {
			switch type {
				case "string": "string"
				case "integer": "int64"
				case "float": "float64"
				case "boolean": "bool"
			}
		}
		
		def Set<ComponentType> getUsedComponentTypes(System system) {
			val types = newLinkedHashSet
			system.boards.forEach[
				elements.filter(Component).forEach[
					types.add(type)
				]
			]
			return types
		}
	
}