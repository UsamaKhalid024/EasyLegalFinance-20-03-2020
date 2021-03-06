import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors } from 'c/ldsUtils';

import getPreviousLoans from '@salesforce/apex/PaymentController.getPreviousLoans';
import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
import { fireEvent, unregisterAllListeners, registerListener } from 'c/pubsub';
import { flatten } from 'c/flatley';

const PERMISSION_CLASSES = [
    'Can_Schedule_Payments',
    'Can_Process_Scheduled_Payments'
]

export default class PreviousLoanManager extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @api leadId;
    @api oppId;

    @track columns;
    expandedData;
    @track data;
    @track error;

    @track boolTrue = true;
    @track boolFalse = false;

    @track showAdd = true;
    _shown = false;
    @api 
    get shown() {
        return this._shown;
    }
    set shown(value) {
        this._shown = !!value;
        this.setShowHideText();
    }
    @track showHideText = "Show";
    @track showHideIcon = "utility:chevrondown";

    @track sortedBy = "Name";
    @track sortedDirection = 'asc'; 

    @track disabledEditFields = ['Opportunity__c'];
    @track selectedPreviousLoan; // Used to pass information to different forms
    @track selectedPreviousLoanId;
    @track previousPreviousLoanAmount;
    @track showCreateForm = false;
    @track showEditForm = false;
    @track showScheduleForm = false;
    @track loading = true;

    permissions = {};

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
            this.showAdd = this.permissions.Can_Schedule_Payments;
        }
    }

    wiredResults;

    @wire(getPreviousLoans, { opportunityId: '$oppId'})//, leadId: '$leadId' })
    imperativeWiring(result) {
        this.loading = false;
        this.wiredResults = result;
        // flatten results
        if (result.data) {
            this.expandedData = result.data;
            this.flattenData();
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    @api
    refresh() {
        this.loading = true;
        return refreshApex(this.wiredResults)
            .finally(() => { this.loading = false; }); 
    }

    get shouldShowTable() {
        return this.data && this.shown;
    }

    constructor() {
        super();
        this.columns = [
            { label: 'Name', fieldName: 'Name', type: 'string', sortable: true },
            { label: 'Lender', fieldName: 'lenderUrl', type: 'url', typeAttributes: {target: '_blank', label: {fieldName: 'Lender__r.Name'}}, sortable: true },
            { label: 'Amount', fieldName: 'Amount__c', type: 'currency', sortable: true },
            { label: 'Payout Statement', fieldName: 'Payout_Statement_on_File__c', type: 'Boolean', sortable: true },
            { label: 'Valid Until', fieldName: 'Date_Payout_Valid_Until__c', type: 'date-local', typeAttributes: {'time-zone': "UTC"}, sortable: true },
            { label: 'Status', fieldName: 'Status__c', sortable: true },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ]
    }

    connectedCallback() {
        this.flattenData();
        registerListener(`previousloanschanged-${this.oppId}`, this.refresh, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    flattenData() {
        if (this.expandedData) {
            let flattenedData = [];
            this.expandedData.forEach(eRow => {
                let row = flatten(eRow);
                row.lenderId = row['Lender__r.Id'];
                row.lenderUrl = row.lenderId ? `/${row.lenderId}` : '';
                flattenedData.push(row);
            });
            this.data = flattenedData;
            this.sortData(this.sortedBy, this.sortedDirection);
        }
    }

    handleShowHideClick(event) {
        this.shown = !this.shown;
        this.setShowHideText();
    }

    setShowHideText() {
        if (this.shown) {
            this.showHideText = 'Hide';
            this.showHideIcon = 'utility:chevronup';
        } else {
            this.showHideText = "Show";
            this.showHideIcon = "utility:chevrondown";
        }
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        if (row.Status__c === 'Closed') {
            actions.push({
                label: 'Can not be edited',
                name: 'do_not_edit',
                disabled: true
            });
            doneCallback(actions);
        } else {
            // Don't have access to "this" in this context, so make a callout each time...
            fetchCustomPermissions({permissions: [
                'Can_Schedule_Payments'
            ]}).then(result => {
                if (result.Can_Schedule_Payments) {
                    if (row.Status__c === 'Ready to Schedule') {
                        actions.push({
                            label: 'Schedule Payout',
                            iconName: 'action:new_event',
                            name: 'schedule_payout'
                        });
                    } else if (row.Status__c === 'Scheduled') {
                        actions.push({
                            label: 'Edit Scheduled Payout',
                            iconName: 'action:new_event',
                            name: 'schedule_payout'
                        });
                    } 
                    actions.push({
                        label: 'Edit',
                        iconName: 'utility:edit',
                        name: 'edit'
                    });
                    if (row.Status__c === 'Collecting Information' || row.Status__c === 'Payout Date Expired' || row.Status__c === 'Ready to Schedule') {
                        actions.push({
                            label: 'Delete',
                            iconName: 'utility:delete',
                            name: 'delete'
                        });
                    }
                } else {
                    actions.push({
                        label: 'Can not be edited',
                        name: 'do_not_edit',
                        disabled: true
                    });
                }
                doneCallback(actions);
            }, error => {
                actions.push({
                    label: 'Can not be edited',
                    name: 'do_not_edit',
                    disabled: true
                });
                doneCallback(actions);
            });
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'edit':
                this.disabledEditFields = ['Opportunity__c'];
                this.selectedPreviousLoan = row;
                this.showEditModal();
                break;
            case 'schedule_payout':
                this.selectedPreviousLoan = row;
                if (this.oppId)
                    this.showScheduleModal();
                break;
            default:
        }
    }

    deleteRow(row) {
        this.loading = true;
        deleteRecord(row.Id)
            .then(() => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully deleted previous loan',
                        variant: 'success'
                    })
                );
                this.fireLoansChanged();
                return this.refresh();
            })
            .catch(error => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: reduceErrors(error).join(', '),
                        variant: 'error'
                    })
                );
            });
    }

    updateColumnSorting(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, sortDirection) {
        const reverse = sortDirection === 'asc' ? 1 : -1;

        // Make copy of data as wired data is immutable
        let _data = JSON.parse(JSON.stringify(this.data));
        //this.data.forEach(obj => _data.push({...obj}))

        switch(fieldName) {
            case 'Scheduled_Date__c':
                _data.sort((a, b) => reverse * (new Date(a[fieldName]) - new Date(b[fieldName])));
                break;
            default:
                _data.sort(function(a, b) {
                    if (a[fieldName] < b[fieldName]) {
                        return reverse * -1;
                    } else if (a[fieldName] > b[fieldName]) {
                        return reverse
                    }
                    return 0
                });
        }
        this.data = _data;
    }

    /* CREATE MODAL METHODS */

    handleCreateSuccess(event) {
        this.refresh();
        this.hideCreateModal();
        this.fireLoansChanged();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully created a new previous loan',
                variant: 'success'
            })
        );
    }

    showCreateModal() {
        this.showCreateForm = true;
        const modal = this.template.querySelector("c-modal.createModal")
        modal.show();
    }

    hideCreateModal() {
        this.showCreateForm = false;
        const modal = this.template.querySelector("c-modal.createModal")
        modal.hide();
    }
    /* END CREATE MODAL METHODS */

    /* EDIT MODAL METHODS */
    handleEditSuccess(event) {
        this.refresh();
        this.hideEditModal();
        this.fireLoansChanged();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully updated the previous loan',
                variant: 'success'
            })
        );
    }

    showEditModal() {
        this.showEditForm = true;
        const modal = this.template.querySelector("c-modal.editModal")
        modal.show();
    }

    hideEditModal() {
        this.showEditForm = false;
        const modal = this.template.querySelector("c-modal.editModal")
        modal.hide();
    }
    /* END EDIT MODAL METHODS */

    /* SCHEDULE MODAL METHODS */
    handleScheduleSuccess(event) {
        // TODO setup pubsub send event stating the SPs have changed
        this.refresh();
        this.hideScheduleModal();
        fireEvent(this.pageRef, `scheduledpaymentschanged-${this.oppId}`)
        this.fireLoansChanged();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully updated the scheduled payout',
                variant: 'success'
            })
        );
    }

    showScheduleModal() {
        this.showScheduleForm = true;
        const modal = this.template.querySelector("c-modal.scheduleModal")
        modal.show();
    }

    hideScheduleModal() {
        this.showScheduleForm = false;
        const modal = this.template.querySelector("c-modal.scheduleModal")
        modal.hide();
    }
    /* END SCHEDULE MODAL METHODS */

    fireLoansChanged() {
        const filterChangeEvent = new CustomEvent('loanschanged', {});
        // Fire the custom event
        this.dispatchEvent(filterChangeEvent);
    }
}