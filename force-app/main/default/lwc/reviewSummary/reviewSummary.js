import { LightningElement, api, track } from 'lwc';

export default class ReviewSummary extends LightningElement {
    @track displayItems = [];

    _workflowType = '';
    _formDataJson = '';
    _fieldConfigJson = '';
    _formData = {};
    _fieldConfig = [];
    message = '';

    /**
     * Returns workflow type.
     * @returns {String} Workflow type.
     */
    @api
    get workflowType() {
        return this._workflowType;
    }

    /**
     * Sets workflow type.
     * @param {String} value - Workflow type.
     */
    set workflowType(value) {
        this._workflowType = value || '';
    }

    /**
     * Returns form data JSON.
     * @returns {String} Form data JSON.
     */
    @api
    get formDataJson() {
        return this._formDataJson;
    }

    /**
     * Parses form data JSON.
     * @param {String} value - Form data JSON.
     */
    set formDataJson(value) {
        this._formDataJson = value || '';
        this._formData = this.parseJsonObject(this._formDataJson, {});
        this.buildDisplayList();
    }

    /**
     * Returns field config JSON.
     * @returns {String} Field config JSON.
     */
    @api
    get fieldConfigJson() {
        return this._fieldConfigJson;
    }

    /**
     * Parses field config JSON.
     * @param {String} value - Field config JSON.
     */
    set fieldConfigJson(value) {
        this._fieldConfigJson = value || '';
        this._fieldConfig = this.parseJsonArray(this._fieldConfigJson, []);
        this.buildDisplayList();
    }

    /**
     * Returns the rendered card title.
     * @returns {String} Summary title.
     */
    get summaryTitle() {
        return this._workflowType ? `${this._workflowType} Review Summary` : 'Review Summary';
    }

    /**
     * Returns true when a message should be rendered.
     * @returns {Boolean} Message visibility.
     */
    get hasMessage() {
        return Boolean(this.message);
    }

    /**
     * Flow screen API: read-only summary always passes component validation.
     * @returns {Object} Flow validation result.
     */
    @api
    validate() {
        return { isValid: true };
    }

    /**
     * Flow screen API: no internal inputs to validate.
     */
    @api
    reportValidity() {}

    /**
     * Builds label/value display rows.
     */
    buildDisplayList() {
        const labelMap = this.buildLabelMap();
        const entries = Object.entries(this._formData || {});
        this.displayItems = entries.map(([key, value]) => this.toDisplayItem(key, value, labelMap));
        this.message = this.displayItems.length ? '' : 'No review data available.';
    }

    /**
     * Builds field name to label map.
     * @returns {Object} Label map.
     */
    buildLabelMap() {
        return (this._fieldConfig || []).reduce((labelMap, field) => {
            if (field && field.name) labelMap[field.name] = field.label || field.name;
            return labelMap;
        }, {});
    }

    /**
     * Converts one form data entry to a display item.
     * @param {String} key - Field key.
     * @param {*} value - Field value.
     * @param {Object} labelMap - Label map.
     * @returns {Object} Display item.
     */
    toDisplayItem(key, value, labelMap) {
        return {
            label: labelMap[key] || this.humanizeKey(key),
            value: this.formatValue(value),
            labelKey: `${key}-label`,
            valueKey: `${key}-value`
        };
    }

    /**
     * Converts a fallback key into a readable label.
     * @param {String} key - Raw form data key.
     * @returns {String} Human-readable key.
     */
    humanizeKey(key) {
        return key
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .replace(/[_-]+/g, ' ')
            .replace(/\b\w/g, (character) => character.toUpperCase());
    }

    /**
     * Formats values for read-only display.
     * @param {*} value - Raw value.
     * @returns {String} Display value.
     */
    formatValue(value) {
        if (value === true) return 'Yes';
        if (value === false) return 'No';
        if (value === null || value === undefined || value === '') return '-';
        return String(value);
    }

    /**
     * Parses JSON into an object safely.
     * @param {String} jsonValue - JSON string.
     * @param {Object} fallbackValue - Fallback object.
     * @returns {Object} Parsed object.
     */
    parseJsonObject(jsonValue, fallbackValue) {
        const parsedValue = this.parseJson(jsonValue, fallbackValue);
        return parsedValue && !Array.isArray(parsedValue) ? parsedValue : fallbackValue;
    }

    /**
     * Parses JSON into an array safely.
     * @param {String} jsonValue - JSON string.
     * @param {Array} fallbackValue - Fallback array.
     * @returns {Array} Parsed array.
     */
    parseJsonArray(jsonValue, fallbackValue) {
        const parsedValue = this.parseJson(jsonValue, fallbackValue);
        return Array.isArray(parsedValue) ? parsedValue : fallbackValue;
    }

    /**
     * Parses JSON safely.
     * @param {String} jsonValue - JSON string.
     * @param {*} fallbackValue - Fallback value.
     * @returns {*} Parsed value.
     */
    parseJson(jsonValue, fallbackValue) {
        if (!jsonValue) return fallbackValue;
        try {
            return JSON.parse(jsonValue);
        } catch (error) {
            this.logError('Invalid reviewSummary JSON input.', error);
            return fallbackValue;
        }
    }

    /**
     * Logs recoverable parse errors.
     * @param {String} message - Log message.
     * @param {Error} error - Error object.
     */
    logError(message, error) {
        // eslint-disable-next-line no-console
        console.error(message, error);
    }
}
