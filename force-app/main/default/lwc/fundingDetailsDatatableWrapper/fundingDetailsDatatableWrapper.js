/* eslint-disable @lwc/lwc/no-async-operation */
import { api, LightningElement, track } from 'lwc';
import { getSortedFlattenedSPList, flattenSPList } from 'c/fundingDetailsUtils';
//import { showToast } from 'c/showToast';
import { generateDataTableErrors } from 'c/ldsUtils';

export default class FundingDetailsDatatableWrapper extends LightningElement {
    @api enableInfiniteLoading;
    @api pageSize = 20;

    @api keyField = "Id";

    @track paginatedData;

    _fullData;
    @api 
    get fullData() {
        return this._fullData;
    }
    set fullData(value) {
        if (value && value.length) {
            flattenSPList(value)
                .then(result => {
                    this._fullData = result;
                    this.sortData();
                });
        } else {
            this.paginatedData = [];
        }
    }
    _sortedBy;
    @api 
    get sortedBy() {
        return this._sortedBy
    }
    set sortedBy(value) {
        this._sortedBy = value;
        this.sortData();
    }
    _sortedDirection;
    @api 
    get sortedDirection() {
        return this._sortedDirection
    }
    set sortedDirection(value) {
        this._sortedDirection = value;
        this.sortData();
    }

    @api columns;

    @api suppressBottomBar = false;
    @api hideCheckboxColumn; 

    @track _selectedRows = [];
    @api
    get selectedRows(){
        return this.getTable().selectedRows;
    }
    set selectedRows(value){
        this._selectedRows = value || [];
    }
    @track _draftValues;
    @api
    get draftValues(){
        return this.getTable().draftValues;
    }
    set draftValues(value){
        this._draftValues = value || [];
    }
    @track _errors; 
    @api
    get errors(){
        return this.getTable().errors;
    }
    set errors(value){
        this._errors = value || [];
    }

    @api getPaginatedData() {
        return this.paginatedData
    }

    @api generateErrors(errorsString) {
        this._errors = generateDataTableErrors(JSON.parse(errorsString), this.paginatedData);
    }

    _table;
    getTable() {
        this._table = this._table || this.template.querySelector('c-funding-details-datatable');
        return this._table;
    }

    connectedCallback() {
        this.enableInfiniteLoading = true;
        this.addEventListener('loadmore', this.loadMore.bind(this));
        this.addEventListener('sort', this.updateColumnSorting.bind(this));
    }

    sortData() {
        window.clearTimeout(this.searchTimeout);
        (function (_this) {
            _this.searchTimeout = setTimeout(() => {
                if (_this.fullData && _this.fullData.length) {
                    if (_this.sortedBy && _this.sortedDirection) {
                        getSortedFlattenedSPList(_this._fullData, _this.sortedBy, _this.sortedDirection)
                            .then(result => {
                                _this._fullData = result;
                                _this.setPaginatedData();
                            });
                    }
                }
            }, 10);
        })(this);
    }

    loadMore() {
        if (this.fullData.length <= this.pageSize || this.fullData.length === this.paginatedData.length) {
            this.enableInfiniteLoading = false;
        } else {
            this.paginatedData = this.fullData.slice(0, this.paginatedData.length + this.pageSize);
        }
    }

    setPaginatedData() {
        this.enableInfiniteLoading = true;
        this.paginatedData = [...this.fullData.slice(0, this.pageSize)];
    }

    updateColumnSorting(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        getSortedFlattenedSPList(this._fullData, fieldName, sortDirection)
            .then(result => {
                this._fullData = result;
                this.setPaginatedData();
            });
    }

    handleEvent(event) {
        let newEvent = new CustomEvent(event.type, event); // Make a copy that has not been dispatched and dispatch it from this component
        this.dispatchEvent(newEvent);
    }
    /*
    @api onsave; // ;{handleSave}
    @api oncancel; // {handleCancel}
    */
}