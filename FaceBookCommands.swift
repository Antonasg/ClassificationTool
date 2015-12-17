//
//  FaceBookCommands.swift
//  SwiftCLI
//
//  Created by Anton Gregersen on 29/11/15.
//  Copyright © 2015 Anton Gregersen. All rights reserved.
//

import Foundation


class FacebookCommand: CommandType {
    let commandName = "facebook"
    let commandShortDescription = "Run facebook command"
    let commandSignature = "" //<person>
    
    var messages = Array<Message>()
	
	//Keywords arrays
	let effectiveArray = ["effektiv","effektivitet","mobilitet", "optimere", "optimering","hurtigere", "hastighed", "ubesværet", "bilkø", "trafikprop"]
	let effectiveNonTrafficWords = ["effektiv", "effektivitet", "mobilitet", "optimere", "optimering", "hurtigere", "ubesværet"]
	
	let co2Array = ["co2","klima","miljøvenlig", "grøn","grønnere", "forurening","forurene", "klimaændringer", "drivhusgasser", "udledning", "udslip", "co2-neutral"]
	let c02NonTrafficWords = ["co2","klima","miljøvenlig", "grøn","grønnere", "forurening","forurene", "klimaændringer", "drivhusgasser", "udledning", "udslip", "co2-neutral"]
	
	let safetyArray = ["sikkerhed", "sikkerhed", "færdselsulykker", "færdselsulykke", "trafikulykke", "trafikulykker", "dødelighed", "påkørsel", "påkørt", "dødsfald", "sammenstød", "trafikuheld", "spritbilist", "spritkørsel"]
	let safetyNonTrafficWords = ["sikker", "sikkerhed", "dødelighed", "dødsfald"]
	
	
	let nonTrafficPages = ["politi","koebenhavnskommune"]
	let trafficKeywordsArray = ["trafik"]
	
    func execute(arguments: CommandArguments) throws  {
        //do shit
        
        let filePath = FileManager.currentDirectory() + "/FBT_with_count_comment_info.csv"
        print(filePath)

        var inputString: String
        do {
            inputString = try String(contentsOfFile: filePath)
        } catch {
            print("File does not exist")
            exit(0)
        }
        
        let csv = CSwiftV(String: inputString)
        print("headers:")
        print(csv.headers)
        
        for (_,element) in csv.rows.enumerate() {
            let message = element[1]
            let likeCount = element[2]
            let pageName = element[8];
            let messageObj = Message(message: message, likeCount: likeCount, pageName: pageName)
            self.messages.append(messageObj)
        }
        self.computeRelevance()
		self.exportToCSV()
		exit(0)
    }
    
    
    func computeRelevance() {
		//Keywords arrays
        //analyse each comment to see if words from either set exists
        for message in self.messages {
			//optimization analysis
			if nonTrafficPages.contains(message.pageName) { //a non-traffic related page
				// check comment contains words from trafficKeywordsArray, then analyse for keywords
				// else is false
				if (array(trafficKeywordsArray, containsArray: message.messageArray)) {
					//the array has trafik keywords
					analyse(message)
				} else {
					// the array does not have any trafic keywords, so it should just be false...i.e. default values.
				}
			} else { //traffic related page
				analyse(message)
			}
			
        }

		
    }
	
	func analyse(message:Message) {
		//effective analysis
		if (array(effectiveArray, containsArray: message.messageArray)) {
			message.isOptimize = true
			message.commentType.append("Optimize")
		} else {
			message.isOptimize = false
		}
		//co2 analysis
		if (array(co2Array, containsArray: message.messageArray)) {
			message.isCO2 = true
			message.commentType.append("Co2")
		} else {
			message.isCO2 = false
		}
		//safety analysis
		if (array(safetyArray, containsArray: message.messageArray)) {
			message.isSafety = true
			message.commentType.append("Safety")
		} else {
			message.isSafety = false
		}
	}
	
	func array(keywordArray:[String],containsArray:[String]) -> Bool {
		let optiFoundList = keywordArray.filter( { containsArray.contains($0) == true } )
		if (optiFoundList.count > 0) {
			return true
		} else {
			return false
		}
	}
	
    func exportToCSV(){
        print("start writing to file...")
		
        let fileName = FileManager.currentDirectory() + "/myFile.csv"
        //["comment_id", "comment_message", "comment_like_count", "comment_time_created", "comment_made_by_id", "comment_made_by_name", "post_id", "comment_made_to_id", "comment_made_to_name", "replies_count", "length_of_message", "tags_count", "id"]
        var data  = "comment_message,comment_like_count,comment_made_to_name,type\n"
        
        for message in self.messages {
			
			//comment trimming commas and new lines:
            var messageString = message.message.stringByReplacingOccurrencesOfString(",", withString: "")
			messageString = messageString.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
			let splitArray = messageString.splitOnNewLine()
			var comment: String = ""
			for line in splitArray {
				comment += line
			}
			
			//type stuff:
			var type = ""
			//new
			if (message.commentType.count > 0) {
				for element in message.commentType {
					type += element
				}
				//moved:
				comment += ","
				let like = "\(message.likeCount),"
				let pageName = message.pageName + ","
				type += "\n"
				let complete = comment + like + pageName + type
				
				data.appendContentsOf(complete)
			} else {
				type = "none"
			}
			
			
        }

        do {
            print("writing...")
            try data.writeToFile(fileName, atomically: false, encoding: NSUTF8StringEncoding)
        } catch _ {
            print("failed to write file ")
        }
        
        print("new csv file is complete")
    }
    
    
}