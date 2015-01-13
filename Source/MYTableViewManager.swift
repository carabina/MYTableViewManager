//
//  MYTableViewManager.swift
//  MYTableViewManager
//
//  Created by Le Van Nghia on 1/13/15.
//  Copyright (c) 2015 Le Van Nghia. All rights reserved.
//


import UIKit

public enum MYReloadType {
    case InsertRows(UITableViewRowAnimation)
    case DeleteRows(UITableViewRowAnimation)
    case ReloadSection
    case ReleadTableView
}

public class MYTableViewManager : NSObject {
    typealias MYTableViewCellDataList = [MYTableViewCellData]
    
    private weak var tableView: UITableView?
    private var dataSource: [Int: MYTableViewCellDataList] = [:]
    private var headerViewData: [Int: MYHeaderFooterViewData] = [:]
    private var footerViewData: [Int: MYHeaderFooterViewData] = [:]
    private var numberOfSections: Int = 0
    private var selectedCells = [MYBaseViewProtocol]()
    
    subscript(index: Int) -> [MYTableViewCellData] {
        get {
            if dataSource.indexForKey(index) != nil {
                return dataSource[index]!
            } else {
                numberOfSections = max(numberOfSections, index + 1)
                dataSource[index] = []
                return dataSource[index]!
            }
        }
        set(newValue) {
            dataSource[index] = newValue
        }
    }
    
    public func setup(tableView: UITableView) {
        self.tableView = tableView
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    public func appendDataForSection(section: Int, data: [MYTableViewCellData], reloadType: MYReloadType) {
        if dataSource.indexForKey(section) != nil {
            self.setBaseViewDataDelegate(data)
            dataSource[section]! += data
            
            switch reloadType {
            case .InsertRows(let animation):
                let startRowIndex = dataSource[section]!.count - data.count
                let endRowIndex = startRowIndex + data.count
                let indexPaths = (startRowIndex..<endRowIndex).map { index -> NSIndexPath in
                    return NSIndexPath(forRow: index, inSection: section)
                }
                tableView?.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
                
            case .ReloadSection:
                let indexSet = NSIndexSet(index: section)
                tableView?.reloadSections(indexSet, withRowAnimation: .None)
                
            default:
                tableView?.reloadData()
            }
            return
        }
        
        resetDataForSection(section, data: data, reloadSection: true)
    }
    
    public func resetDataForSection(section: Int, data: [MYTableViewCellData], reloadSection: Bool = false) {
        self.setBaseViewDataDelegate(data)
        
        let insertAction = numberOfSections < section + 1
        numberOfSections = max(numberOfSections, section + 1)
        dataSource[section] = data
        if reloadSection {
            let indexSet = NSIndexSet(index: section)
            if insertAction {
                tableView?.insertSections(indexSet, withRowAnimation: .None)
            } else {
                tableView?.reloadSections(indexSet, withRowAnimation: .None)
            }
        }
    }
    
    public func setHeaderDataForSection(section: Int, data: MYHeaderFooterViewData) {
        headerViewData[section] = data
    }
    
    public func setFooterDataForSection(section: Int, data: MYHeaderFooterViewData) {
        footerViewData[section] = data
    }
    
    public func enableHeaderViewForSection(section: Int) {
        if let data = headerViewData[section] {
            data.isEnabled = true
        }
    }
    
    public func disableHeaderViewForSection(section: Int) {
        if let data = headerViewData[section] {
            data.isEnabled = false
        }
    }
    
    public func enableFooterViewForSection(section: Int) {
        if let data = footerViewData[section] {
            data.isEnabled = true
        }
    }
    
    public func disableFooterViewForSection(section: Int) {
        if let data = footerViewData[section] {
            data.isEnabled = false
        }
    }
    
    public func deselectAllCells() {
        for view in selectedCells {
            view.unhighlight(true)
        }
        selectedCells.removeAll(keepCapacity: false)
    }
}

// MARK - private methods
private extension MYTableViewManager {
    private func addSelectedView(view: MYBaseViewProtocol) {
        deselectAllCells()
        selectedCells = [view]
    }
    
    private func setBaseViewDataDelegate(dataList: [MYBaseViewData]) {
        for data in dataList {
            data.delegate = self
        }
    }
}

// MARK - MYBaseViewDataDelegate
extension MYTableViewManager : MYBaseViewDataDelegate {
    public func didSelectView(view: MYBaseViewProtocol) {
        addSelectedView(view)
    }
}

// MARK - UITableViewDelegate
extension MYTableViewManager : UITableViewDelegate {
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cellData = dataSource[indexPath.section]?[indexPath.row] {
            return cellData.cellHeight
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let data = headerViewData[section] {
            return data.isEnabled ? data.viewHeight : 0
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let data = headerViewData[section] {
            if !data.isEnabled {
                return nil
            }
            let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(data.identifier) as MYHeaderFooterView
            headerView.setData(data)
            return headerView
        }
        return nil
    }
    
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let data = footerViewData[section] {
            return data.isEnabled ? data.viewHeight : 0
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let data = footerViewData[section] {
            if !data.isEnabled {
                return nil
            }
            let footerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(data.identifier) as MYHeaderFooterView
            footerView.setData(data)
            return footerView
        }
        return nil
    }
}

// MARK - MYTableViewManager
extension MYTableViewManager : UITableViewDataSource {
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section]?.count ?? 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellData = dataSource[indexPath.section]![indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellData.identifier, forIndexPath: indexPath) as MYTableViewCell
        cell.setData(cellData)
        return cell
    }
}