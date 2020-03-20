import { loadStyle } from 'lightning/platformResourceLoader';
import fundingDetailsGlobalCss from '@salesforce/resourceUrl/fundingDetailsGlobalCss';
//import flatley from '@salesforce/resourceUrl/flatley';
import updateScheduledPayments from '@salesforce/apex/FundingDetailsComponentCtlr.updateScheduledPayments';
import { flatten } from 'c/flatley';

const loadGlobalCss = (comp) => {
    return loadStyle(comp, fundingDetailsGlobalCss);
};

/*
const loadFlatley = (comp) => {
    return loadScript(comp, flatley + '/index.js')
}
*/

const groupPayments = (spList, groupingField, noFlatten) => {
    groupingField = groupingField || 'Current_Bank_Account_Name__c'; // Default to Current Bank Account Name
    return new Promise(resolve => {
        let summaryMap = {};
        let data = [];
        spList.forEach(sp => {
            let parentRow;
            if (!summaryMap.hasOwnProperty(sp[groupingField])) {
                // initilize grouping for payment account
                parentRow = {...sp};
                parentRow['Id'] = sp.Current_Bank_Account_Name__c + '-summary';
                parentRow['address'] = sp.account.BillingAddress;
                parentRow['Expected_Admin_Fee_Amount__c'] = 0;
                parentRow['Amount__c'] = 0;
                parentRow['_children'] = [];
                summaryMap[sp[groupingField]] = parentRow;
                data.push(parentRow);
            } else {
                parentRow = summaryMap[sp[groupingField]];
            }
            if (noFlatten) {
                parentRow._children.push(sp);
            } else {
                parentRow._children.push(flatten(sp));
            }
            parentRow.Expected_Admin_Fee_Amount__c += sp.Expected_Admin_Fee_Amount__c;
            parentRow.Amount__c += sp.Amount__c;
        });
        resolve(data);
    })
}

const combineData = (data) => {
    return new Promise(resolve => {
        let combinedData = {
            spMap: {},
            spList: data.scheduled_payments,
            oppMap: data.opportunities,
            accMap: data.accounts
        }


        // Set opportunity reference on Scheduled Payments
        combinedData.spList.forEach(sp => {
            sp.account = combinedData.accMap[sp.Current_Account_Id__c];

            sp.opportunity = combinedData.oppMap[sp.Opportunity__c]; // Nest opp Object for EFT tables
            combinedData.spMap[sp.Opportunity__c] = combinedData.spMap[sp.Opportunity__c] || []; // Nest
            combinedData.spMap[sp.Opportunity__c].push(sp);
        });
        resolve(combinedData);
    })
}

const generateObjectFromDraftValue = (sobjectType, draftValue) => {
    let newObj = {'sobjectType': sobjectType, 'Id': draftValue.Id};
    for (const key in draftValue) {
        if (key !== 'id' && draftValue.hasOwnProperty(key)) {
            newObj[key] = draftValue[key];
        }
    }
    return newObj;
};

const download = (filename, text) => {
    var element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.setAttribute('download', filename);

    element.style.display = 'none';
    document.body.appendChild(element);

    element.click();

    document.body.removeChild(element);
};

const buildAccountLinks = (row) => {
    row.client_account_url = row['opportunity.AccountId'];
    row._client_account = {
        url: `/lightning/r/Account/${row['opportunity.Account.Id']}/view`,
        label: row['opportunity.Account.Name']
    };
    if (row['Account__r.Name']) {
        row.Account__c = {
            url: `/lightning/r/Account/${row['Account__r.Id']}/view`,
            label: row['Account__r.Name']
        };
    } else {
        row.Account__c = row._client_account;
    }
}

const getSortedFlattenedSPList = async (flattenedList, fieldName, sortDirection) => {
        const reverse = sortDirection === 'asc' ? 1 : -1;

        // Make copy of data as wired data is immutable
        let _data = [...flattenedList];

        switch(fieldName) {
            case 'Scheduled_Date__c':
            case 'Sent_to_Bank_Date__c':
            case 'paymentDate':
            case 'Verified_Date__c':
                _data.sort((a, b) => {
                    if (!a[fieldName] && !b[fieldName]) {
                        return 0
                    } else if (!a[fieldName]) {
                        return reverse * -1
                    } else if (!b[fieldName]) {
                        return reverse
                    }
                    return reverse * (new Date(a[fieldName]) - new Date(b[fieldName]))
                });
                break;
            case '_client_account':
            case 'Account__c':
                _data.sort((a, b) => {
                    var nameA = a[fieldName].label.toUpperCase(); // ignore upper and lowercase
                    var nameB = b[fieldName].label.toUpperCase(); // ignore upper and lowercase
                    if (nameA < nameB) {
                        return reverse * -1;
                    }
                    if (nameA > nameB) {
                        return reverse;
                    }

                    // names must be equal
                    return 0;
                });
                break;
            default:
                _data.sort((a, b) => {
                    if (a[fieldName] < b[fieldName]) {
                        return reverse * -1;
                    } else if (a[fieldName] > b[fieldName]) {
                        return reverse
                    }
                    return 0
                });
        }
        return _data
    }

const flattenSPList = (spList) => {
    return new Promise(resolve => {
        let flattenedList = [];
        const flatleyOptions = {
            filters: [
                {test: (key, value) => key.endsWith('Address')} // Don't flatten Address Objects
            ]
        };
        for (let index = 0; index < spList.length; index++) {
            let row = flatten(spList[index], flatleyOptions);
            buildAccountLinks(row);
            flattenedList.push(row);
        }

        resolve(flattenedList);
    });
}

const updateSPList = (spList, updatedSPs) => {
    if (updatedSPs.length) {
        updatedSPs.forEach(sp => {
            // let spListIdx = this.spList.findIndex(record => {return record.Id === sp.Id});
            let spListIdx = spList.findIndex(record => {return record.Id === sp.Id});
            for (const key in sp) {
                if (key !== 'Id' && sp.hasOwnProperty(key)) {
                    // this.spList[spListIdx] = sp[key];
                    spList[spListIdx][key] = sp[key];
                }
            }
        });
    }
    return spList
}

const updateFlattenedListFromResult = (flattenedList, result) => {
    if (result.length) {
        result.forEach(sp => {
            let flattenedListIdx = flattenedList.findIndex(record => {return record.Id === sp.Id});
            for (const key in sp) {
                if (key !== 'Id' && sp.hasOwnProperty(key)) {
                    flattenedList[flattenedListIdx][key] = sp[key];
                }
            }
        });
    }
    return flattenedList;
}

const sendScheduledPaymentsChangedEvent = (comp, payload) => {
    const evt = new CustomEvent("scheduledpaymentschanged", {
        //bubbles: true,
        detail: payload
    });
    comp.dispatchEvent(evt);
}

const sendNeedsRefreshEvent = (comp) => {
    const evt = new CustomEvent("needsrefresh", {});
    comp.dispatchEvent(evt);
}

const updateScheduledPaymentsFromDraftValues = (draftValues) => {
    let updateSPList = [];
    draftValues.forEach(draftValue => {
        updateSPList.push(generateObjectFromDraftValue('Scheduled_Payment__c', draftValue));
    });
    return updateScheduledPayments({scheduledPayments: updateSPList})
}

//const mergeOpportunitiesIntoScheduledPayments = (data) => {
    // expecting data.scheduled_payments to be a list
    // expecting data.opportunities to be a map of <oppId, Opp>
//}

const PERMISSION_CLASSES = [
    'EFT_Permission',
    'Can_Schedule_Payments',
    'Can_Process_Scheduled_Payments'
]

export {
    generateObjectFromDraftValue,
    download,
    combineData,
    groupPayments,
    loadGlobalCss,
    //loadFlatley,
    buildAccountLinks,
    getSortedFlattenedSPList,
    flattenSPList,
    updateSPList,
    updateFlattenedListFromResult,
    updateScheduledPaymentsFromDraftValues,
    sendNeedsRefreshEvent,
    sendScheduledPaymentsChangedEvent,
    PERMISSION_CLASSES
}