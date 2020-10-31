//
//  ViewController.swift
//  MyCarsCoreData
//
//  Created by Николаев Никита on 29.10.2020.
//  Copyright © 2020 Николаев Никита. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car: Car!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.selectedSegmentTintColor = .white
            
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            segmentedControl.setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            segmentedControl.setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
        }
    }
    @IBOutlet weak var myChoiseImageView: UIImageView!
    
    @IBAction func choiceAction(_ sender: UISegmentedControl) {
        updateSegmentedControl()
    }
    @IBAction func startAction(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    @IBAction func rateAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car, please", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func update(rating: Double) {
        car.rating = rating
        do {
            try context.save()
            updateMyChoise()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong Value", message: "Wrong Input", preferredStyle: .alert)
            let okAktion = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAktion)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
    
    private func updateMyChoise() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "rating", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let objects = try context.fetch(fetchRequest)
            guard let firstObject = objects.first else { return }
            let maxRating = firstObject.rating
            for object in objects {
                if object.rating < maxRating {
                    object.myChoice = false
                } else {
                    object.myChoice = true
                }
            }
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func updateSegmentedControl() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func getDataFromFile() {
        
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: ".plist"),
        let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
        
        for dictionary in dataArray {
            guard let entity = NSEntityDescription.entity(forEntityName: "Car", in: context) else { return }
            let car = NSManagedObject(entity: entity, insertInto: context) as! Car
            
            let carDictionary = dictionary as! [String: AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            if let imageName = carDictionary["imageName"] as? String {
                let image = UIImage(named: imageName)
                let imageData = image?.pngData()
                car.imageData = imageData
            }
            
            if let colorDictionary = carDictionary["tintColor"] as? [String : Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
        }
        
        print("Data is obtained from the data.plist file")
        
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func getColor(colorDictionary: [String : Float]) -> UIColor {
        guard let red = colorDictionary["red"],
            let green = colorDictionary["green"],
            let blue = colorDictionary["blue"]
        else { return UIColor() }
        
        return UIColor(red: CGFloat(red/255),
                       green: CGFloat(green/255),
                       blue: CGFloat(blue/255),
                       alpha: 1.0)
    }
    
    private func insertDataFrom(selectedCar car: Car) {
        if let carImageData = car.imageData {
            carImageView.image = UIImage(data: carImageData)
        }
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiseImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating)/10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: car.lastStarted!))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !Settings.dataObtained{
            getDataFromFile()
            Settings.dataObtained = true
        }
        updateSegmentedControl()
//        clearCoreData()
    }
    
    func clearCoreData() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        if let objects = try? context.fetch(fetchRequest) {
            for object in objects {
                context.delete(object)
            }

            do {
                try print(context.count(for: fetchRequest))
                try context.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            Settings.dataObtained = false
        }
    }

}

