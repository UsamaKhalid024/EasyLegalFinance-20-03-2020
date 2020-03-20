import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getReportData from '@salesforce/apex/reportComponentController.getReportData';

export default class ReportTable extends LightningElement {
    @track loading = true;
    @track report;
    @api reportId;
    _stringFilters;
    _filtersObj;
    @api 
    get filters() {
        return this._filtersObj
    }
    set filters(value) {
        this._filtersObj = value;
        if (value) {
            this._stringFilters = JSON.stringify(value)
        } else {
            this._stringFilters = ""
        }
    }

    wiredReportDataResults;

    @wire(getReportData, { reportId: '$reportId', filters: '$_stringFilters' })
    wiredGetReportData(result) {
        this.loading = false;
        this.wiredReportDataResults = result;
        if (result.data) {
            this.report = JSON.parse(result.data);
            this.generateKeys();
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    @api
    refresh() {
        console.dir(this.reportId);
        console.dir(this.filters);
        console.dir(this.wiredResults);
        this.loading = true;
        return refreshApex(this.wiredReportDataResults)
            .finally(() => { this.loading = false; }); 
    }

    connectedCallback() {
        console.dir(this.reportId);
        console.dir(this.filters);
        console.dir(this.wiredResults);
    }

    generateKeys() {
        this.generateHeaderKeys();
        this.generateGroupKeys();
        this.generateRowKeys();
    }

    generateGroupKeys() {
        if (this.isSummary) {
            this.report.sumResp.groupList.forEach((group, rowIdx) => {
                group.key = `${group.fieldLabel}-${rowIdx}`;
                group.fieldDataList.forEach((cell, cellIdx) => {
                    cell.key = `${group.fieldLabel}-${rowIdx}-${cellIdx}`;
                })
            })
        }
    }

    generateRowKeys() {
        if (!this.isSummary) {
            this.report.tabResp.fieldDataList.forEach((cell, cellIdx) => {
                cell.key = `${cell.fieldLabel}-${cellIdx}`;
            })
        }
    }

    generateHeaderKeys() {
        const reportFields = this.isSummary ? this.report.sumResp.reportFields : this.report.tabResp.reportFields;
        reportFields.forEach((field, idx) => {
            field.key = `${field.fieldLabel}-${idx}`;
        });
    }

    get isSummary() {
        if (this.report) {
            return this.report.reportType === 'summary'
        }
        return false
    }
}