import { LightningElement, track, api } from 'lwc';
//import * as moment from 'c/moment';
import { loadScript } from 'lightning/platformResourceLoader';
import momentUrl from '@salesforce/resourceUrl/moment';

export default class DateRangePicker extends LightningElement {
    // emits change event with an object {start: <startDate>, end: <endDate>}
    initCompleted = false;
    @api timezone = 'UTC';

    @track presetOptions; 
    _timePeriod = 'future';
    @api 
    get timePeriod() {
        return this._timePeriod
    }
    set timePeriod(value) {
        this._timePeriod = value;
        this.setPresetOptions();
    }

    setPresetOptions() {
        if (this.timePeriod === 'past') {
            this.presetOptions = [
                {label: 'Today', value: 'today'},
                {label: 'Previous 7 Days', value: 'previous_7_days'},
                {label: 'Previous 30 Days', value: 'previous_30_days'},
                {label: 'This Week', value: 'this_week'},
                {label: 'Previous Week', value: 'previous_week'},
                {label: 'This Month', value: 'this_month'},
                {label: 'Previous Month', value: 'previous_month'},
                {label: 'All Time', value: 'all'},
            ];
        } else {
            this.presetOptions = [
                {label: 'Today', value: 'today'},
                {label: 'Next 7 Days', value: 'next_7_days'},
                {label: 'Next 30 Days', value: 'next_30_days'},
                {label: 'This Week', value: 'this_week'},
                {label: 'Next Week', value: 'next_week'},
                {label: 'This Month', value: 'this_month'},
                {label: 'Next Month', value: 'next_month'},
                {label: 'All Time', value: 'all'},
            ];
        }
    }

    _filterNeedsInit = false;
    _filters = {preset: undefined};
    @api
    get filters() {
        return this._filters
    }
    set filters(value) {
        // check if preset is included and changed
        // Init is double running and sending back no dates upon first init
        this._filterNeedsInit = false;
        if (value) {
            if (!this._filters || (value && value.preset && this._filters.preset !== value.preset)) {
                this._filterNeedsInit = true;
            }
            this._filters = value ? {...value} : {preset: undefined};
            if (this.initCompleted) {
                this.initFilter();
            }
        } else {
            this._filters = {preset: undefined};
            this.formattedStartDate = this.formattedEndDate = undefined;
        }
    }

    initFilter() {
        if (this._filterNeedsInit) {
            this._filterNeedsInit = false;
            if (this.initCompleted) {
                this.setPresetValues().then(this.sendInitEvent());
            }
        } else {
            if (this.initCompleted) {
                let newStartDate = this.formatDate(this.filters.startDate);
                let newEndDate = this.formatDate(this.filters.endDate);
                if (this.formattedStartDate != newStartDate || this.formattedEndDate != newEndDate) {
                    this.formattedStartDate = newStartDate;
                    this.formattedEndDate = newEndDate;
                    this.sendInitEvent();
                }
            }
        }
    }

    @track formattedStartDate;
    @track formattedEndDate;

    _resourcesLoaded = false;

    connectedCallback() {
        // load moment
        if (!this._resourcesLoaded) {
            this._resourcesLoaded = true;
        }
        this.setPresetOptions();
        loadScript(this, momentUrl + '/moment.js')
            .then(() => {
                this.initCompleted = true;
                if (this.filters) {
                    this.initFilter();
                } else {
                    this.sendInitEvent();
                }
            });
    }

    async setPresetValues() {
        this.filters.startDate = this.filters.startDate ? moment(this.filters.startDate) : undefined;
        this.filters.endDate = this.filters.endDate ? moment(this.filters.endDate) : undefined;
        if (this.filters.preset) {
            let dt = moment().utc();
            switch (this.filters.preset) {
                case 'today':
                    this.filters.startDate = dt.startOf('day');
                    this.filters.endDate = moment(dt).endOf('day');
                    //this.filters.endDate = moment(dt).add({days: 7}).startOf('day');
                    break;
                case 'this_week':
                    this.filters.startDate = dt.startOf('isoWeek').startOf('day');
                    this.filters.endDate = moment(dt).endOf('isoWeek').endOf('day');
                    break;
                case 'this_month':
                    this.filters.startDate = dt.startOf('month').startOf('day');
                    this.filters.endDate = moment(dt).endOf('month').endOf('day');
                    break;
                case 'previous_7_days':
                    this.filters.endDate = dt.endOf('day');
                    this.filters.startDate = moment(dt).subtract({days: 7}).startOf('day');
                    break;
                case 'previous_30_days':
                    this.filters.endDate = dt.endOf('day');
                    this.filters.startDate = moment(dt).subtract({days: 30}).startOf('day');
                    break;
                case 'previous_week':
                    dt = dt.subtract({weeks: 1});
                    this.filters.startDate = dt.startOf('isoWeek').startOf('day');
                    this.filters.endDate = moment(dt).endOf('isoWeek').endOf('day');
                    break;
                case 'previous_month':
                    dt = dt.subtract({months: 1});
                    this.filters.startDate = dt.startOf('month').startOf('day');
                    this.filters.endDate = moment(dt).endOf('month').endOf('day');
                    break;
                case 'next_7_days':
                    this.filters.startDate = dt.startOf('day');
                    this.filters.endDate = moment(dt).add({days: 7}).endOf('day');
                    break;
                case 'next_30_days':
                    this.filters.startDate = dt.startOf('day');
                    this.filters.endDate = moment(dt).add({days: 30}).endOf('day');
                    break;
                case 'next_week':
                    dt = dt.add({weeks: 1});
                    this.filters.startDate = dt.startOf('isoWeek').startOf('day');
                    this.filters.endDate = moment(dt).endOf('isoWeek').endOf('day');
                    break;
                case 'next_month':
                    dt = dt.add({months: 1});
                    this.filters.startDate = dt.startOf('month').startOf('day');
                    this.filters.endDate = moment(dt).endOf('month').endOf('day');
                    break;
                case 'all':
                    this.filters.startDate = null;
                    this.filters.endDate = null;
                    break;
                default:
                    break;
            }
            this.formattedStartDate = this.formatDate(this.filters.startDate);
            this.formattedEndDate = this.formatDate(this.filters.endDate);
        }
    }

    formatDate(value) {
        // toISOString seems to be messing things up. I should format manually in the user's current timezone
        return value ? moment(value).format('YYYY-MM-DD') : null
    }

    sendInitEvent() {
        let evt = new CustomEvent('filterinit', {
            detail: {
                preset: this.filters.preset,
                startDate: this.formatDate(this.filters.startDate),
                endDate: this.formatDate(this.filters.endDate)
            }
        });
        this.dispatchEvent(evt);
    }

    handlePresetChange(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        this.filters.preset = event.target.value;
        this.setPresetValues();
        this.sendChangeEvent();
    }

    handleStartChange(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        this.filters.preset = null;

        this.filters.startDate = event.target.value ? moment(event.target.value) : null;
        if (this.filters.startDate && this.filters.endDate && moment(this.filters.startDate) > moment(this.filters.endDate)) {
            this.filters.endDate = this.filters.startDate;
        }
        this.formattedStartDate = this.formatDate(this.filters.startDate);
        this.formattedEndDate = this.formatDate(this.filters.endDate);
        this.sendChangeEvent();
    }

    handleEndChange(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        this.filters.preset = null;

        this.filters.endDate = event.target.value ? moment(event.target.value) : null;
        if (this.filters.startDate && this.filters.endDate && moment(this.filters.startDate) > moment(this.filters.endDate)) {
            this.filters.startDate = this.filters.endDate;
        }
        this.formattedStartDate = this.formatDate(this.filters.startDate);
        this.formattedEndDate = this.formatDate(this.filters.endDate);
        this.sendChangeEvent();
    }

    sendChangeEvent(eventName) {
        eventName = eventName || 'change';
        let evt = new CustomEvent(eventName, {
            detail: {
                preset: this.filters.preset,
                startDate: this.formatDate(this.filters.startDate),
                endDate: this.formatDate(this.filters.endDate)
            }
        });
        this.dispatchEvent(evt);
    }

    @api getDates() {
        return {
            startDate: this.filters.startDate,
            endDate: this.filters.endDate 
        }
    }
}