//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate, CLLocationManagerDelegate, FiltersViewControllerDelegate {
    
    var businesses: [Business]!
    var filtered: [Business]!
    
    var isFiltered: Bool = false
    var isMoreDataLoading: Bool = false
    var offset: Int = 0
    var dealstate: Bool?
    var sorttype: Int?
    var categories: [String]?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    var rightBtn: UIButton!
    var listOrMap: Bool = false // false: table, true: map
    
    var locationManager: CLLocationManager!
    
    var searchBar: UISearchBar!
    var searchActive: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120
        
        self.searchBar = UISearchBar()
        self.searchBar.sizeToFit()
        self.navigationItem.titleView = self.searchBar
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Restaurants"
        self.searchBar.tintColor = UIColor.white
        
        /*
        // let rightItem = UIBarButtonItem(image: UIImage(named: "map"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(BusinessesViewController.toggleView))
        // let rightBtnView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0))
        rightBtn = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0))
        rightBtn.setBackgroundImage(UIImage(named: "map"), for: UIControlState.normal)
        rightBtn.addTarget(self, action: #selector(BusinessesViewController.toggleView), for: UIControlEvents.touchUpInside)
        let rightBarBtn = UIBarButtonItem(customView: rightBtn)
        self.navigationItem.setRightBarButton(rightBarBtn, animated: true)
        */
        
        self.mapView.frame = CGRect(x: 0.0, y: 0.0, width: self.tableView.frame.size.width, height: self.tableView.frame.size.height)
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.distanceFilter = 200
        
        
        self.mapView.isHidden = true
        self.tableView.isHidden = false
        
        Business.searchWithTerm(term: "Chinese", limit: 20, offset: 0, completion: { (businesses: [Business]?, error: Error?) -> Void in
            
            self.offset = 0
            self.businesses = businesses
            self.tableView.reloadData()
            })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /****************************
    // MARK: - Navigation
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let filtersViewController = navigationController.topViewController as! FiltersViewController
        filtersViewController.delegate = self
    }
    
    
    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String : AnyObject]) {
        
        print("\nReally try to search new Yelp\n")
        self.isFiltered = true
        self.dealstate = filters["deal"] as? Bool
        self.sorttype = filters["sort"] as? Int
        self.categories = filters["categories"] as? [String]
        self.offset = 0
        
        Business.searchWithTerm(term: "Restaurants", sort: self.sorttype.map { YelpSortMode(rawValue: $0) }!, categories: self.categories, deals: self.dealstate, limit: 20, offset: 0) { (businesses, error) in
            print("\n\n This search get \(businesses!.count) items.\n\n")
            self.businesses = businesses
            if self.listOrMap {
                self.removeAllAnnotations()
                for restaurant in self.businesses {
                    let coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude!, longitude: restaurant.longitude!)
                    self.addAnnotationAtCoordinate(coordinate: coordinate, title: restaurant.name!)
                }
            } else {
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    
    /****************************
    // MARK: - TableView delefate functions
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchActive {
            return filtered?.count ?? 0
        } else {
            return self.businesses?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BusinessCell", for: indexPath) as! BusinessCell
        
        if self.searchActive {
            cell.business = self.filtered[indexPath.row]
        } else {
            cell.business = self.businesses[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    /****************************
    // MARK: - SearchBar delegate functions
    */
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchActive = false
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchActive = false
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchActive = false
        self.searchBar.resignFirstResponder()
        self.searchBar.text = ""
        self.searchBar.showsCancelButton = false
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filtered = self.businesses.filter({ (result) -> Bool in
            
            //let range = title.rangeOfString(searchText, options: NSString.CompareOptions.CaseInsensitiveSearch)
            let range = result.name?.range(of: searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)
            return (range != nil)
        })
        self.searchActive = true
        if searchText == "" {
            self.searchActive = false
        }
        self.tableView.reloadData()
        
        /*
        if listOrGrid {
            self.movieCollection.reloadData()
        } else {
            self.movieTable.reloadData()
        }
        */
    }
    
    
    /****************************
    // MARK: - ScrollView delegate functions
    */
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !(self.isMoreDataLoading) {
            let scrollViewContentHeight = self.tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - self.tableView.bounds.size.height
            
            if scrollView.contentOffset.y > scrollOffsetThreshold && self.tableView.isDragging {
                self.isMoreDataLoading = true
                self.loadMoreData()
            }
        }
    }
    
    
    /****************************
    // MARK: - MapView functions
    */
    
    func goToLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    /*
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            self.mapView.setRegion(region, animated: true)
        }
    }
    */
    
    func addAnnotationAtCoordinate(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        self.mapView.addAnnotation(annotation)
    }
    
    func removeAllAnnotations() {
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
    }
    
    
    
    /****************************
    // MARK: - Helper functions
    */
    
    func loadMoreData() {
        if self.isFiltered {
            Business.searchWithTerm(term: "Restaurants", sort: self.sorttype.map { YelpSortMode(rawValue: $0) }!, categories: self.categories, deals: self.dealstate, limit: 20, offset: self.offset+20) { (businesses, error) in
                
                for business in businesses! {
                    self.businesses.append(business)
                }
                self.offset += 20
                self.tableView.reloadData()
                self.isMoreDataLoading = false
            }
        } else {
            Business.searchWithTerm(term: "Chinese", limit: 20, offset: self.offset+20, completion: { (businesses: [Business]?, error: Error?) -> Void in
                
                for business in businesses! {
                    self.businesses.append(business)
                }
                self.offset += 20
                self.tableView.reloadData()
                self.isMoreDataLoading = false
                
                }
            )
        }
        
    }
    
    @IBAction func toggleView(sender: AnyObject?) {
        if self.listOrMap {
            self.listOrMap = false
            self.mapView.isHidden = true
            self.tableView.isHidden = false
            
            // self.rightBtn.setBackgroundImage(UIImage(named: "map"), for: UIControlState.normal)
            let navBarRightBtn = self.navigationItem.rightBarButtonItem
            navBarRightBtn?.title = "Map"
            // navBarRightBtn?.image = UIImage(named: "map")
        } else {
            self.listOrMap = true
            self.tableView.isHidden = true
            self.mapView.isHidden = false
            
            // self.rightBtn.setBackgroundImage(UIImage(named: "list"), for: UIControlState.normal)
            let navBarRightBtn = self.navigationItem.rightBarButtonItem
            navBarRightBtn?.title = "List"
            // navBarRightBtn?.image = UIImage(named: "list")
            
            self.locationManager.requestWhenInUseAuthorization()
            let centerLocation = CLLocation(latitude: 37.785771, longitude: -122.342165)
            self.goToLocation(location: centerLocation)
            
            for restaurant in self.businesses {
                let coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude!, longitude: restaurant.longitude!)
                addAnnotationAtCoordinate(coordinate: coordinate, title: restaurant.name!)
            }
        }
    }
    
}
