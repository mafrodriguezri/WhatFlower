//
//  ViewController.swift
//  WhatFlower
//
//  Created by Manuel on 5/5/19.
//  Copyright © 2019 ManuelRR. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var wikiExtractLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikiURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    
    //MARK: - Picking the image and analysis using the CoreML model
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickerImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = userPickerImage
            
            guard let ciImage = CIImage(image: userPickerImage) else {fatalError("Could not convert UIImage into CIImage")}
            
            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("loading CoreML model failed")}
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let result = request.results?.first as? VNClassificationObservation else {fatalError("Model failed to process image")}
            print(result)
            
            let confidenceValue = result.confidence
            let flowerName = self.specificFlowerWiki(flowerIndetifier: result.identifier)
            
                self.navigationItem.title = "\(result.identifier.capitalized)"+" - \(Int(Double(confidenceValue)*100))%"
                
                self.getFlowerWiki(flowerName: flowerName)           
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    
    //MARK: - Networking using Alamofire
    func getFlowerWiki(flowerName: String) {
        
        let parameters : [String : String] = ["format":"json", "action":"query", "prop":"extracts|pageimages", "exintro":"", "explaintext":"", "titles":flowerName, "indexpageids":"", "redirects":"1", "pithumbsize":"500"]
        
        Alamofire.request(wikiURL, method: .get, parameters: parameters).responseJSON { response in
            
            if response.result.isSuccess {
                
                let extractJSON : JSON = JSON(response.result.value!)
                self.getFlowerWikiExtract(json: extractJSON)
                
            } else {
                print("Error: \(String(describing: response.result.error))")
                self.wikiExtractLabel.text = "Connection issues. Description not available."
            }
        }
    }
    
    //MARK: - Parsing the JSON data
    func getFlowerWikiExtract(json: JSON) {
        
        let pageId = json["query"]["pageids"][0].stringValue
        
        let extract = json["query"]["pages"][pageId]["extract"].stringValue
            print(extract)
            wikiExtractLabel.text = extract
        
        let flowerImageURL = json["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
        
        if let url = NSURL(string: flowerImageURL) {
            if let data = NSData(contentsOf: url as URL) {
                if let image = UIImage(data: data as Data) {
                    imageView.image = image
                }
            }
        }
    }
    
    func specificFlowerWiki(flowerIndetifier: String) -> String {
        
        var resultFlower = flowerIndetifier
    
        if resultFlower == "tiger lily" || resultFlower == "fire lily"{
            resultFlower = "Lilium bulbiferum"
        } else if resultFlower == "bird of paradise" {
            resultFlower = "Strelitzia"
        } else if resultFlower == "colt's foot" {
            resultFlower = "Petasites"
        } else if resultFlower == "pincushion flower" {
            resultFlower = "Scabiosa"
        } else if resultFlower == "prince of wales feathers" {
            resultFlower = "Amaranthus hypochondriacus"
        } else if resultFlower == "stemless gentian" {
            resultFlower = "Gentiana acaulis"
        } else if resultFlower == "love in the mist" {
            resultFlower = "Nigella damascena"
        } else if resultFlower == "ruby-lipped cattleya" {
            resultFlower = "Cattleya labiata"
        } else if resultFlower == "cape flower" {
            resultFlower = "Plumbago auriculata"
        } else if resultFlower == "great masterwort" {
            resultFlower = "Astrantia major"
        } else if resultFlower == "marigold" {
            resultFlower = "Calendula"
        } else if resultFlower == "bishop of llandaff" {
            resultFlower = "Dahlia 'Bishop of Llandaff'"
        } else if resultFlower == "orange dahlia" || resultFlower == "pink-yellow dahlia?"{
            resultFlower = "Dahlia"
        } else if resultFlower == "black-eyed susan" {
            resultFlower = "Rudbeckia hirta"
        } else if resultFlower == "silverbush" {
            resultFlower = "Convolvulus cneorum"
        } else if resultFlower == "windflower" {
            resultFlower = "Anemone nemorosa"
        } else if resultFlower == "tree poppy" {
            resultFlower = "Bocconia frutescens"
        } else if resultFlower == "water lily" {
            resultFlower = "Nymphaeaceae"
        } else if resultFlower == "thorn apple" {
            resultFlower = "Datura"
        } else if resultFlower == "lotus" {
            resultFlower = "Nelumbo nucifera"
        } else if resultFlower == "columbine" {
            resultFlower = "Aquilegia"
        } else if resultFlower == "desert-rose" {
            resultFlower = "Adenium obesum"
        } else if resultFlower == "mallow" {
            resultFlower = "Malva"
        }
        
        return resultFlower
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}
