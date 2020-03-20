import { LightningElement, wire, api, track } from 'lwc';
//import { refreshApex } from '@salesforce/apex';
//import { reduceErrors } from 'c/ldsUtils';

import fetchCustomPermissions from '@salesforce/apex/FetchCustomPermissions.fetchCustomPermissions';
//import getScheduledPaymentsWithOpportunities from '@salesforce/apex/FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities';
//import resetTestInfo from '@salesforce/apex/ScheduledPaymentHelper.resetTestInfo';
//import getOpportunitiesWithScheduledPayments from '@salesforce/apex/FundingDetailsComponentCtlr.getOpportunitiesWithScheduledPayments';
//import { CurrentPageReference } from 'lightning/navigation';
//import { fireEvent } from 'c/pubsub';
import { PERMISSION_CLASSES } from 'c/fundingDetailsUtils';

export default class FundingDetails_Parent extends LightningElement {
    @track permissions = {};
    @track currentStage = "Staging";

    @track filterTimePeriod = 'future';
    activeFilterName = 'staging';
    @track filters = {
        staging: {preset: 'this_week'},
        all: {preset: 'all'},
        closed: {preset: 'today'},
    }
    @track activeFilter = this.filters[this.activeFilterName];
    @track hideFilters = true;
    @track hideSearch = true;
    @track queryTerm;

    tabQuerySelector = 'c-funding-details-staging-area';
    @track filterInitilized = false;

    @wire(fetchCustomPermissions, {permissions: PERMISSION_CLASSES})
    setPermissions(result) {
        if (result.data) {
            this.permissions = result.data;
        }
    }

    tabConfiguration = {
        Staging: {
            currentStage: 'Staging',
            filterName: 'staging',
            filterTimePeriod: 'future',
            hideFilters: false,
            hideSearch: false,
            tabQuerySelector: 'c-funding-details-staging-area'
        },

        ValidateEfts: {
            currentStage: 'ValidateEfts',
            filterName: 'staging',
            filterTimePeriod: 'future',
            hideFilters: false,
            hideSearch: true,
            tabQuerySelector: 'c-funding-details-validate-efts.eft'
        },

        BankingSheet: {
            currentStage: 'BankingSheet',
            filterName: 'staging',
            filterTimePeriod: 'future',
            hideFilters: false,
            hideSearch: true,
            tabQuerySelector: 'c-funding-details-update-and-generate-banking-sheet'
        },

        InputEfts: {
            currentStage: 'InputEfts',
            filterName: 'all',
            filterTimePeriod: 'future',
            hideFilters: false,
            hideSearch: true,
            tabQuerySelector: 'c-funding-details-update-eft'
        },

        ValidateCheques: {
            currentStage: 'ValidateCheques',
            filterName: 'staging',
            filterTimePeriod: 'future',
            hideFilters: false,
            hideSearch: true,
            tabQuerySelector: 'c-funding-details-validate-efts.cheque'
        },

        SendCheques: {
            currentStage: 'SendCheques',
            filterName: 'staging',
            filterTimePeriod: 'future',
            hideFilters: false,
            hideSearch: true,
            tabQuerySelector: 'c-funding-details-send-cheques'
        },

        OpportunityTable: {
            currentStage: 'OpportunityTable',
            filterName: 'closed',
            filterTimePeriod: 'past',
            hideFilters: false,
            hideSearch: true,
            tabQuerySelector: 'c-funding-details-opportunity-table'
        },

        CompletedPayments: {
            currentStage: 'CompletedPayments',
            filterName: 'closed',
            filterTimePeriod: 'past',
            hideFilters: false,
            hideSearch: false,
            tabQuerySelector: 'c-funding-details-completed-payments'
        },

    }

    connectedCallback() {
        // TODO - get history from url
    }

    tabSelected(event) {
        this.selectTab(event.target.value);
        //console.dir(JSON.parse(JSON.stringify(event)));
        //debugger;
    }

    selectTab(stageName) {
        this.currentStage = stageName;
        this.tabQuerySelector = this.tabConfiguration[this.currentStage].tabQuerySelector;
        let newFilterName = this.tabConfiguration[this.currentStage].filterName;
        if (this.activeFilterName != newFilterName) {
            //this.filterInitilized = false;
            this.activeFilterName = newFilterName;
            this.activeFilter = this.filters[this.activeFilterName];
        }
        this.filterTimePeriod = this.tabConfiguration[this.currentStage].filterTimePeriod;
        this.hideFilters = this.tabConfiguration[this.currentStage].hideFilters;
        this.hideSearch = this.tabConfiguration[this.currentStage].hideSearch;
        this.queryTerm = '';
    }

    get canSendPayments() {
        return this.permissions.EFT_Permission;
    }

    get canInputEFTNumbers() {
        return this.permissions.Can_Process_Scheduled_Payments;
    }

    get canProcessAndValidateLoan() {
        return this.permissions.Can_Process_Scheduled_Payments;
    }

    get canReviewClosedPayments() {
        return this.permissions.Can_Process_Scheduled_Payments;
    }

    /* VISIBILITY SETTERS */
    /* VISIBILITY SETTERS */

    /* VISIBILITY GETTERS */
    get shouldShowSharedFilter() {
        return this.shouldShowStaging || this.shouldShowValidateEfts || this.shouldShowBankingSheet || this.shouldShowValidateCheques || this.shouldShowSendCheques || this.shouldShowCompletedPayments
    }

    get shouldShowStaging() {
        return this.currentStage === "Staging" && this.canProcessAndValidateLoan
    }

    get shouldShowValidateEfts() {
        return this.currentStage === "ValidateEfts" && this.canProcessAndValidateLoan
    }

    get shouldShowBankingSheet() {
        return this.currentStage === "BankingSheet" && this.canSendPayments
    }

    get shouldShowInputEfts() {
        return this.currentStage === "InputEfts" && this.canProcessAndValidateLoan
    }

    get shouldShowValidateCheques() {
        return this.currentStage === "ValidateCheques" && this.canProcessAndValidateLoan
    }

    get shouldShowSendCheques() {
        return this.currentStage === "SendCheques" && this.canProcessAndValidateLoan
    }

    get shouldShowOpportunityTable() {
        return this.currentStage === "OpportunityTable" && this.canProcessAndValidateLoan
    }

    get shouldShowCompletedPayments() {
        return this.currentStage === "CompletedPayments" && this.canProcessAndValidateLoan
    }
    /* VISIBILITY GETTERS */

    handleStagingFilterInitialized(event) {
        // Get Active Tab
        // Refresh Active Tab
        this.filters[this.activeFilterName] = event.detail || {};
        this.activeFilter = this.filters[this.activeFilterName];
        this.filterInitilized = true;
        /*
        if (this.resourcesInitialized) {
            this.refresh();
        }
        */
    }

    handleStagingFilterChange(event) {
        this.filters[this.activeFilterName] = event.detail || {};
        this.activeFilter = this.filters[this.activeFilterName];
    }

    refresh() {
        let cmp = this.template.querySelector(this.tabQuerySelector);
        if (cmp) {
            cmp.refresh();
        }
    }

    handleSearchKeyup(event) {
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            window.clearTimeout(this.searchTimeout);
            this.queryTerm = event.target.value;
        }
    }

    handleSearchChange(event) {
        window.clearTimeout(this.searchTimeout);
        //this.queryTerm = event.target.value;
        
        (function (_this, value) {
            _this.searchTimeout = setTimeout(() => {
                _this.queryTerm = value;
            }, 300);
        })(this, event.target.value);
        
    }

}