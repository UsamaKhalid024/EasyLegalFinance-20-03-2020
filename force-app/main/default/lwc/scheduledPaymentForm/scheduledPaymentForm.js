import { LightningElement, api, track } from 'lwc';
import getBankAccountOptions from '@salesforce/apex/ScheduledPaymentHelper.getBankAccountOptions';
import { showToast } from 'c/showToast';

export default class ScheduledPaymentForm extends LightningElement {
    @api recordId;
    @api disabledFields = [];
    @api opportunity;
    @api opportunityServiceProvider;
    @api account;
    @api hold;
    @api sendCheque;
    @api usePrimaryBankAccount;
    @api bankAccount;
    @api scheduledDate;
    @api amount;
    @api maxAmount;
    @api previousLoan;
    @api paymentType;
    @api status;

    @track loading = false;

    primaryBankAccountFound = false;
    primaryBankAccount;
    @track bankAccountOptions;
    @track showBankAccountForm = false;

    connectedCallback() {
        if (this.account) {
            this.refreshBankAccountOptions();
        }
        if (!this.recordId) {
            this.setDisabledFields(this.paymentType);
        }
        if (this.rejecting) {
            this.hold = true;
        }
    }

    refreshBankAccountOptions() {
        getBankAccountOptions({accId: this.account})
            .then(result => {
                this.primaryBankAccountFound = false;
                this.bankAccountOptions = result.map(ba => {
                    let label = '';
                    if (ba.Is_Primary_Account__c) {
                        this.primaryBankAccountFound = true;
                        this.primaryBankAccount = ba.Id;
                        label = '* ';
                        if (!this.bankAccount || this.usePrimaryBankAccount) {
                            this.bankAccount = ba.Id; // Default to primary 
                        }
                    }
                    label += `${ba.Name} - ${ba.Account__c}`;
                    return { value: ba.Id, label: label}
                });
            })
            .catch(reason => {
                showToast(
                    this,
                    'Error Fetching Bank Accounts',
                    JSON.stringify(reason),
                    'error'
                );
            })
    }

    get opportunityDisabled() {
        return !this.loading && this.disabledFields.indexOf('Opportunity__c') !== -1
    }

    get dateDisabled() {
        return !this.loading && this.disabledFields.indexOf('Scheduled_Date__c') !== -1
    }

    get amountDisabled() {
        return !this.loading && this.disabledFields.indexOf('Amount__c') !== -1
    }

    get accountDisabled() {
        return !this.loading && (this.disabledFields.indexOf('Account__c') !== -1 || !this.opportunity)
    }

    get usePrimaryAccountDisabled() {
        return !this.loading && this.sendCheque
    }
    
    get bankAccountDisabled() {
        return !this.loading && (this.sendCheque || this.usePrimaryBankAccount || !this.account || !this.opportunity)
    }

    get showPrimaryBankAccountWarning() {
        return this.usePrimaryBankAccount && !this.primaryBankAccountFound
    }

    handleOpportunityChange(event) {
        this.opportunity = event.target.value;
    }

    handleAccountChange(event) {
        this.account = event.target.value;
        if (this.account) {
            this.refreshBankAccountOptions();
        } else {
            this.bankAccount = undefined;
            this.bankAccountOptions = [];
        }
    }

    handleSendChequeChange(event) {
        this.sendCheque = event.detail.checked;
    }

    handleUsePrimaryBankAccountChange(event) {
        this.usePrimaryBankAccount = event.detail.checked;
        this.bankAccount = this.primaryBankAccount;
    }

    handleBankAccountChange(event) {
        this.bankAccount = event.target.value;
    }

    showNewBankAccountForm(event) {
        this.bankAccount = undefined;
        this.showBankAccountForm = true;
    }

    showEditBankAccountForm(event) {
        this.showBankAccountForm = true;
    }

    handleBankFormCancel(event) {
        this.showBankAccountForm = false;
    }

    handleBankFormSuccess(event) {
        this.usePrimaryBankAccount = false;
        this.showBankAccountForm = false;
        this.refreshBankAccountOptions();
        this.bankAccount = event.detail.id;
    }

    get rejecting() {
        return this.status === 'Rejected'
    }

    handleCancel(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    setDisabledFields(paymentType) {
        if (paymentType === 'Scheduled Facility') {
            this.disabledFields = ['Opportunity__c', 'Amount__c']; //, 'Scheduled_Date__c'];
        } else if (paymentType === 'Payment to Other Lender') {
            this.disabledFields = ['Opportunity__c', 'Account__c', 'Amount__c'];
        } else if (paymentType === 'Treatment') {
            this.disabledFields = ['Opportunity__c', 'Account__c', 'Amount__c'];
        } else if (this.opportunity) {
            this.disabledFields = ['Opportunity__c'];
        }
        if (this.rejecting) {
            this.disabledFields.push('Hold__c')
        }
    }

    alreadyLoaded = false;
    handleLoad(event){
        //this.loading = false;
        if (!this.alreadyLoaded && this.recordId) {
            this.alreadyLoaded = true;
            try {
                // Seems to be a bug when I try to get the field value without cloning the object first
                const fields = JSON.parse(JSON.stringify(event.detail.records[this.recordId])).fields
                this.opportunity = fields.Opportunity__c.value;
                this.account = fields.Account__c.value;
                this.bankAccount = fields.Bank_Account__c.value;
                this.usePrimaryBankAccount = fields.Use_Primary_Bank_Account__c.value;
                this.sendCheque = fields.Send_Cheque__c.value;
                this.refreshBankAccountOptions();
                this.setDisabledFields(fields.Payment_Type__c.value);
            } catch (error) {
                this.account = undefined;
            }
        }
    }

    handleSubmit(event){
        this.loading = true;
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Bank_Account__c = this.bankAccount;
        if (this.previousLoan) {
            fields.Previous_Loan__c = this.previousLoan;
        }
        if (this.paymentType) {
            fields.Payment_Type__c = this.paymentType;
        }
        if (this.opportunityServiceProvider) {
            fields.Opportunity_Service_Provider__c = this.opportunityServiceProvider;
        }
        if (this.rejecting) {
            fields.Status__c = 'Rejected';
        }
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.loading = false;
        event.preventDefault();
        event.stopImmediatePropagation();

        this.dispatchEvent(
            new CustomEvent(
                'success',
                {detail: {...event.detail}}
            ));
    }

    handleError() {
        this.loading = false;
    }

}