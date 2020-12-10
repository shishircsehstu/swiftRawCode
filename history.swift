    import UIKit
    import PDFKit
    
    class HistoryViewController: UIViewController {
        
        @IBOutlet weak var navBarView:UIView!
        @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var emptyView: UIView!
        
        var historyArray:NSMutableArray!
        
        var historyInfo = [History]()
        
        var documentArray:NSMutableArray!
        var documentArrayForHistory:NSMutableArray!
        
        var documentArrayModel = [PDFModel]()
        
        var numberOfpages = [Int]()
        var dateOfDocuments = [String]()
        var  allPhoneNumber = [String]()
        var directoryContentsHistoryFolder = [URL]()
        
        var sidStr = [String]()
        var status = [String]()
        
        
        var sidList: NSMutableArray!
        var statusList: NSMutableArray!
        
        var copySidList: NSMutableArray!
        var copyStatusList: NSMutableArray!
        
        var urlOfPhnNum = [URL]()
        
        lazy var refreshControl: UIRefreshControl = {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action:
                         #selector(handleRefresh(_:)),
                                     for: UIControl.Event.valueChanged)
            //refreshControl.tintColor = UIColor.red
            
            return refreshControl
        }()
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            checkAllSID()
            
         tableView.reloadData()
         
        refreshControl.endRefreshing()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.view.backgroundColor = VIEW_BG_COLOR
            
            // self.setupNavBar()
            
            tableView.tableHeaderView = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
            tableView.tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
            tableView.backgroundColor = UIColor.clear
            
            let nib = UINib(nibName: "myHitoryTableViewCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "myHitoryTableViewCell")
            
            tableView.register(UINib(nibName: "HistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "HistoryCELL")
            
            historyArray = NSMutableArray.init(objects: "History 1", "History 2", "History 3", "History 4", "History 5","History 6","History 7")
            
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 80, right: 0)
            
            setLargeNavBar()
            
            self.tableView.addSubview(self.refreshControl)

            
        }
        
        override func viewWillAppear(_ animated: Bool) {
            
            historyInfo = CoreDataManager.fetchHistory()
            print("histoyc ",historyInfo.count)
            
            
            setLargeNavBar()
            
            self.checkEmptyHistory()
            tableView.reloadData()
            navigationController?.navigationBar.isHidden = false
            checkAllSID()
        }
        
        func checkAllSID()
        {
            
            for i in 0..<historyInfo.count
            {
                
                guard let sts =  historyInfo[i].status else {return}
                
                if sts == "queued" || sts == "sending" || sts == "processing"
                {
                    
                    DispatchQueue.main.async {
                        let newStatus = self.checkFaxStatus(sid: self.historyInfo[i].sID!,indx: i)
                        print("current ",i," ",newStatus)
                    }
                }
            }
        }
        
        func setLargeNavBar()
        {
            
            
            navigationItem.title = "History"
            navigationController?.navigationBar.largeTitleTextAttributes =
                [NSAttributedString.Key.foregroundColor: UIColor(displayP3Red: 66/255, green: 82/255, blue: 134/255, alpha: 1),
                 NSAttributedString.Key.font: UIFont(name: "Poppins-Medium", size: 30) ??
                    UIFont.systemFont(ofSize: 34)]
            
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 18)!], for: .normal)
            
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
            self.navigationController?.navigationBar.topItem?.backBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 18)!], for: .normal)
            
            if #available(iOS 11.0, *) {
                navigationController?.navigationBar.prefersLargeTitles = true
                navigationController?.navigationItem.largeTitleDisplayMode = .automatic
            }
        }
        
        func setupNavBar(){
            
            self.navBarView.backgroundColor = NAVBAR_BAR_TINT_COLOR
            
            self.navigationController?.navigationBar.isHidden = true
            
            if !IS_IPHONE_X_SERIES {
                navBarView.frame = CGRect(x: 0, y: 0, width: DEVICE_WIDTH, height: 64)
                tableView.frame = CGRect(x: 0, y: 82, width: DEVICE_WIDTH, height: DEVICE_HEIGHT - 64)
            }
        }
        
        //MARK:- Document Directory path function
        
        func getFormattedDate(date: Date, format: String) -> String {
            let dateformat = DateFormatter()
            dateformat.dateFormat = format
            return dateformat.string(from: date)
        }
        
        
        func getDirectoryPathOfFloderHistory(folderName: String) -> NSURL
        {
            let documentDirectoryPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString)
            let pathWithFolderName = documentDirectoryPath.appendingPathComponent("History/\(folderName)")
            let url = NSURL(string: pathWithFolderName) // convert path in url
            return url!
        }
        
        
        //MARK: private func
        private func checkEmptyHistory(){
            self.tableView.isHidden = !(historyInfo.count > 0)
            self.emptyView.isHidden = historyInfo.count > 0
        }
    }
    
    //MARK:- TableView delegate
    extension HistoryViewController: UITableViewDelegate,UITableViewDataSource {
        
        func checkFaxStatus(sid: String, indx: Int)->String{
            
            
            var faxStatus = String()
            let loginString = String(format: "%@:%@", MAIN_ACCOUNT_NAME, MAIN_ACCOUNT_TOKEN)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let basicAuthStr = loginData.base64EncodedString()
            
            let url = URL(string: "https://fax.twilio.com/v1/Faxes/\(sid)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Basic \(basicAuthStr)", forHTTPHeaderField: "Authorization")
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                if error != nil{
                    
                    print(error.debugDescription)
                    
                }else{
                    
                    if data != nil {
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any] {
                                
                                faxStatus = json["status"] as! String
                                print("status....",faxStatus)
                                
                                
                                let updateStatusHistory = self.historyInfo[indx]
                                updateStatusHistory.status = faxStatus
                                DELEGATE.saveContext()
                                
                                
                                if faxStatus == "delivered" {
                                    
                                    DispatchQueue.main.async {
                                        let indexpath = IndexPath(row: indx, section: 0)
                                        self.tableView.cellForRow(at: indexpath)
                                        self.tableView.reloadData()
                                    }
                                    
                                }
                                
                            }
                        } catch let error {
                            print(error.localizedDescription)
                            
                        }
                    }
                }
            })
            task.resume()
            
            return faxStatus
        }
        
        
        func deleteAlert(index indexPath:IndexPath){
            
            let alert = UIAlertController(title: "Delete History", message: "Are you sure to delete this history?", preferredStyle: .alert)
            
            
            alert.addAction(UIAlertAction(title: "No", style: .default , handler:{ (UIAlertAction)in
                
                self.tableView.beginUpdates()
                let range = NSMakeRange(0, self.tableView.numberOfSections)
                let sections = NSIndexSet(indexesIn: range)
                self.tableView.reloadSections(sections as IndexSet, with: .none)
                self.tableView.endUpdates()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive , handler:{ (UIAlertAction)in
                
                
                let selectedHistory = self.historyInfo[indexPath.row]
                let folderName = selectedHistory.folderName
                
                DocManager.sharedInstance.deletePathFromDirectory(folderName: folderName!)
                
                let contex = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                contex.delete(selectedHistory)
                
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.historyInfo = CoreDataManager.fetchHistory()
                self.tableView.deleteRows(at: [indexPath], with: .bottom)
                
                self.checkEmptyHistory()
              
                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return historyInfo.count
        }
        
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            let cell = tableView.dequeueReusableCell(withIdentifier:"myHitoryTableViewCell",
                                                     for: indexPath) as! myHitoryTableViewCell
            
            cell.history = historyInfo[indexPath.row]
            
            return cell
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 110.0
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
            
            navigationItem.title = " "
            
            documentArrayModel = DocManager.sharedInstance.getIndividualHistory(folderName: historyInfo[indexPath.row].folderName!)!
            
            let  margedPDFDocument = margePDFAllFiles()
            
            let pdfVC = PDFViewController.init(nibName: "PDFViewController", bundle: nil)
            
            pdfVC.document = margedPDFDocument
            pdfVC.currentPageNo = 0
            
            pdfVC.fromHistory = true
            navigationController?.pushViewController(pdfVC, animated: true)
            
        }
        
        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
        {
            
            let deleteAction = UIContextualAction(style: .normal, title: "") { (action, view, handler) in
                
                self.deleteAlert(index: indexPath)
            }
            
            deleteAction.image = UIImage(named: "delete icon")
            deleteAction.backgroundColor = VIEW_BG_COLOR
            
            
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
            if (editingStyle == .delete) {
                
                /*
                 documentArrayForDraft.removeObject(at: indexPath.row)  // contains thumb images
                 deletePathFromDraft(fileUrl: directoryContentsDraftFloder[indexPath.row]) // delete function call
                 directoryContentsDraftFloder.remove(at: indexPath.row)   // contains path
                 numberOfpages.remove(at: indexPath.row)   // contains page number
                 */
                tableView.deleteRows(at: [indexPath], with: .bottom)
                //  tableView.reloadData()
                
            }
        }
        
        func deletePathFromHistory(fileUrl: URL)
        {
            do {
                print(fileUrl)
                try FileManager.default.removeItem(at: fileUrl)
                print("delete success!")
                
            } catch {
                print("Could not delete file: \(error)")
            }
        }
        
        
        func margePDFAllFiles() -> PDFDocument{
            
            let margeDocument = PDFDocument.init()
            for i in 0..<documentArrayModel.count {
                
                let pdfModel:PDFModel = documentArrayModel[i]//documentArray.object(at: i) as! PDFModel
                let doc = pdfModel.pdfDocument!
                
                for j in 0..<doc.pageCount{
                    let page = doc.page(at: j)
                    margeDocument.insert(page!, at: margeDocument.pageCount)
                }
                
            }
            
            return margeDocument
        }
        
        func generatePdfThumbnail(of thumbnailSize: CGSize , for documentUrl: PDFDocument, atPage pageIndex: Int) -> UIImage? {
            
            let pdfDocument = documentUrl
            let pdfDocumentPage = pdfDocument.page(at: pageIndex)
            return pdfDocumentPage?.thumbnail(of: thumbnailSize, for: PDFDisplayBox.trimBox)
            
        }
        
    }
