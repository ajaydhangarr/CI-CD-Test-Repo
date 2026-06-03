import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

const SUPPORTED_FIELD_TYPES = [
    'text',
    'email',
    'number',
    'phone',
    'date',
    'checkbox',
    'textarea',
    'picklist'
];

const INPUT_TYPE_BY_FIELD_TYPE = {
    text: 'text',
    email: 'email',
    number: 'number',
    phone: 'tel',
    date: 'date'
};

export default class DynamicFormRenderer extends LightningElement {
    @api formDataJson = '{}';
    @api isStepValid = false;
    @api workflowResponseJson = '{}';

    @track formState = this.createEmptyFormState();
    @track fieldConfig = [];
    @track visibleFields = {};

    configurationMessage = 'No field configuration provided.';
    _workflowType = '';
    _currentStep = '';
    _fieldConfigJson;
    _existingDataJson;
    _isConnected = false;
    _isFieldConfigParsed = false;
    _isExistingDataParsed = false;

    /**
     * Returns the workflow type provided by Flow.
     * @returns {String} Workflow type.
     */
    @api
    get workflowType() {
        return this._workflowType;
    }

    /**
     * Stores the workflow type provided by Flow.
     * @param {String} value - Workflow type.
     */
    set workflowType(value) {
        this._workflowType = value || '';
        this.syncWorkflowResponseOutput();
    }

    /**
     * Returns the current workflow step.
     * @returns {String} Current step.
     */
    @api
    get currentStep() {
        return this._currentStep;
    }

    /**
     * Stores the current workflow step.
     * @param {String} value - Current step.
     */
    set currentStep(value) {
        this._currentStep = value || '';
        this.syncWorkflowResponseOutput();
    }

    /**
     * Returns the raw field configuration JSON string.
     * @returns {String} Field configuration JSON.
     */
    @api
    get fieldConfigJson() {
        return this._fieldConfigJson;
    }

    /**
     * Parses the field configuration JSON once per distinct value.
     * @param {String} value - Field configuration JSON string.
     */
    set fieldConfigJson(value) {
        if (this._fieldConfigJson === value && this._isFieldConfigParsed) return;
        this._fieldConfigJson = value;
        this._isFieldConfigParsed = false;
        this.parseFieldConfig();
        this.initializeFormState();
    }

    /**
     * Returns the raw existing data JSON string.
     * @returns {String} Existing data JSON.
     */
    @api
    get existingDataJson() {
        return this._existingDataJson;
    }

    /**
     * Parses existing data once per distinct value.
     * @param {String} value - Existing data JSON string.
     */
    set existingDataJson(value) {
        if (this._existingDataJson === value && this._isExistingDataParsed) return;
        this._existingDataJson = value;
        this._isExistingDataParsed = false;
        this.loadExistingData();
        this.initializeFormState();
    }

    /**
     * Initializes state when the component is inserted into the DOM.
     */
    connectedCallback() {
        this._isConnected = true;
        this.initializeFormState();
    }

    /**
     * Returns true when a configuration message should be rendered.
     * @returns {Boolean} True when configuration message exists.
     */
    get hasConfigurationMessage() {
        return Boolean(this.configurationMessage);
    }

    /**
     * Returns only visible normalized fields enriched for rendering.
     * @returns {Array} Visible field view models.
     */
    get visibleFieldList() {
        return this.fieldConfig
            .filter((field) => this.visibleFields[field.name] === true)
            .map((field) => this.buildFieldViewModel(field));
    }

    /**
     * Handles standard input and textarea changes.
     * @param {Event} event - Input change event.
     */
    handleInputChange(event) {
        const fieldName = event.target.dataset.name;
        this.processFieldChange(fieldName, event.target.value);
    }

    /**
     * Handles checkbox changes.
     * @param {Event} event - Checkbox change event.
     */
    handleCheckboxChange(event) {
        const fieldName = event.target.dataset.name;
        this.processFieldChange(fieldName, event.target.checked);
    }

    /**
     * Handles picklist changes.
     * @param {CustomEvent} event - Combobox change event.
     */
    handlePicklistChange(event) {
        const fieldName = event.target.dataset.name;
        this.processFieldChange(fieldName, event.detail.value || '');
    }

    /**
     * Creates an empty centralized form state object.
     * @returns {Object} Empty form state.
     */
    createEmptyFormState() {
        return {
            values: {},
            errors: {},
            touched: {},
            isValid: false
        };
    }

    /**
     * Initializes the form state after inputs are available.
     */
    initializeFormState() {
        if (!this._isConnected || !this._isFieldConfigParsed) return;
        this.ensureConfiguredValues();
        this.refreshVisibility();
        this.validateFields();
        this.syncAllOutputs();
    }

    /**
     * Parses and normalizes field configuration.
     */
    parseFieldConfig() {
        if (!this._fieldConfigJson) {
            this.applyEmptyConfiguration();
            return;
        }
        try {
            this.applyParsedFieldConfig(JSON.parse(this._fieldConfigJson));
        } catch (error) {
            this.logError('Invalid field configuration format.', error);
            this.applyInvalidConfiguration();
        }
    }

    /**
     * Applies parsed field configuration to component state.
     * @param {Array} parsedConfig - Parsed config array.
     */
    applyParsedFieldConfig(parsedConfig) {
        if (!Array.isArray(parsedConfig)) {
            this.applyInvalidConfiguration();
            return;
        }
        this.fieldConfig = this.normalizeFieldConfigList(parsedConfig);
        this.configurationMessage = this.fieldConfig.length ? '' : 'No field configuration provided.';
        this._isFieldConfigParsed = true;
    }

    /**
     * Applies empty configuration state.
     */
    applyEmptyConfiguration() {
        this.fieldConfig = [];
        this.visibleFields = {};
        this.configurationMessage = 'No field configuration provided.';
        this._isFieldConfigParsed = true;
    }

    /**
     * Applies invalid configuration state.
     */
    applyInvalidConfiguration() {
        this.fieldConfig = [];
        this.visibleFields = {};
        this.configurationMessage = 'Invalid field configuration format.';
        this._isFieldConfigParsed = true;
    }

    /**
     * Loads existing form data into state.
     */
    loadExistingData() {
        if (!this._existingDataJson) {
            this._isExistingDataParsed = true;
            return;
        }
        const parsedData = this.parseJsonSafely(this._existingDataJson, {});
        this.applyExistingValues(parsedData);
    }

    /**
     * Applies parsed existing values to form state.
     * @param {Object} parsedData - Parsed existing values.
     */
    applyExistingValues(parsedData) {
        if (!parsedData || Array.isArray(parsedData) || typeof parsedData !== 'object') return;
        this.formState = {
            ...this.formState,
            values: { ...parsedData },
            errors: {},
            touched: {}
        };
        this._isExistingDataParsed = true;
    }

    /**
     * Parses JSON without crashing the component.
     * @param {String} jsonValue - JSON string.
     * @param {*} fallbackValue - Fallback value.
     * @returns {*} Parsed value or fallback.
     */
    parseJsonSafely(jsonValue, fallbackValue) {
        try {
            return JSON.parse(jsonValue);
        } catch (error) {
            this.logError('Invalid JSON provided to dynamicFormRenderer.', error);
            return fallbackValue;
        }
    }

    /**
     * Normalizes all supported field definitions.
     * @param {Array} fields - Raw field configs.
     * @returns {Array} Normalized supported fields.
     */
    normalizeFieldConfigList(fields) {
        return fields.map((field) => this.normalizeFieldConfig(field)).filter(Boolean);
    }

    /**
     * Normalizes one field configuration.
     * @param {Object} field - Raw field config.
     * @returns {Object|null} Normalized config.
     */
    normalizeFieldConfig(field) {
        if (!field || !field.name) return null;
        const normalizedField = this.buildNormalizedField(field);
        if (!this.isSupportedFieldType(normalizedField.type)) return null;
        return normalizedField;
    }

    /**
     * Builds a normalized field configuration object.
     * @param {Object} field - Raw field config.
     * @returns {Object} Normalized field config.
     */
    buildNormalizedField(field) {
        return {
            name: field.name,
            label: field.label || '',
            type: field.type || 'text',
            required: field.required ?? false,
            placeholder: field.placeholder || '',
            visible: field.visible ?? true,
            minLength: field.minLength || null,
            maxLength: field.maxLength || null,
            options: field.options || [],
            visibleWhen: field.visibleWhen || null
        };
    }

    /**
     * Checks whether a field type is supported.
     * @param {String} fieldType - Field type.
     * @returns {Boolean} True when supported.
     */
    isSupportedFieldType(fieldType) {
        const isSupported = SUPPORTED_FIELD_TYPES.includes(fieldType);
        if (!isSupported) this.logWarning(`Unsupported field type: ${fieldType}`);
        return isSupported;
    }

    /**
     * Ensures every configured field has a state slot.
     */
    ensureConfiguredValues() {
        const values = { ...this.formState.values };
        this.fieldConfig.forEach((field) => this.ensureFieldValue(values, field));
        this.formState = { ...this.formState, values };
    }

    /**
     * Adds a default value for a field when missing.
     * @param {Object} values - Values map.
     * @param {Object} field - Normalized field config.
     */
    ensureFieldValue(values, field) {
        if (Object.prototype.hasOwnProperty.call(values, field.name)) return;
        values[field.name] = field.type === 'checkbox' ? false : '';
    }

    /**
     * Processes a user-entered field value.
     * @param {String} fieldName - Field name.
     * @param {*} fieldValue - New field value.
     */
    processFieldChange(fieldName, fieldValue) {
        if (!fieldName || this.formState.values[fieldName] === fieldValue) return;
        this.updateFieldState(fieldName, fieldValue);
        this.refreshVisibility();
        this.validateFields();
        this.syncAllOutputs();
    }

    /**
     * Updates values and touched state for a field.
     * @param {String} fieldName - Field name.
     * @param {*} fieldValue - Field value.
     */
    updateFieldState(fieldName, fieldValue) {
        this.formState = {
            ...this.formState,
            values: { ...this.formState.values, [fieldName]: fieldValue },
            touched: { ...this.formState.touched, [fieldName]: true }
        };
    }

    /**
     * Rebuilds the visible fields map and clears hidden errors.
     */
    refreshVisibility() {
        const nextVisibleFields = {};
        this.fieldConfig.forEach((field) => {
            nextVisibleFields[field.name] = this.resolveFieldVisibility(field);
        });
        this.visibleFields = nextVisibleFields;
        this.clearHiddenFieldErrors(nextVisibleFields);
    }

    /**
     * Resolves static and conditional field visibility.
     * @param {Object} field - Normalized field config.
     * @returns {Boolean} True when visible.
     */
    resolveFieldVisibility(field) {
        if (field.visibleWhen) return this.evaluateFieldVisibility(field);
        return field.visible === true;
    }

    /**
     * Evaluates visibility for a single field
     * @param {Object} field - normalized field config
     * @returns {Boolean} - true if field should be visible
     */
    evaluateFieldVisibility(field) {
        if (!field.visibleWhen) return true;
        const rule = field.visibleWhen;
        const currentValue = this.formState.values[rule.field] || '';
        if (rule.operator === 'equals') return currentValue === rule.value;
        if (rule.operator === 'notEquals') return currentValue !== rule.value;
        if (rule.operator === 'contains') return currentValue.includes(rule.value);
        return true;
    }

    /**
     * Clears errors for newly hidden fields.
     * @param {Object} nextVisibleFields - Visibility map.
     */
    clearHiddenFieldErrors(nextVisibleFields) {
        const errors = { ...this.formState.errors };
        Object.keys(nextVisibleFields).forEach((fieldName) => {
            if (!nextVisibleFields[fieldName]) errors[fieldName] = null;
        });
        this.formState = { ...this.formState, errors };
    }

    /**
     * Flow screen API: validates before Next/Finish navigation.
     * @returns {Object} Flow validation result.
     */
    @api
    validate() {
        this.markVisibleFieldsTouched();
        const isValid = this.validateFields();
        this.syncAllOutputs();
        return {
            isValid,
            errorMessage: isValid ? null : 'Please complete all required fields correctly before continuing.'
        };
    }

    /**
     * Flow screen API: surfaces validation errors after a failed navigation attempt.
     */
    @api
    reportValidity() {
        this.markVisibleFieldsTouched();
        this.validateFields();
        this.syncAllOutputs();
    }

    /**
     * Marks all visible fields as touched so validation messages render on navigation.
     */
    markVisibleFieldsTouched() {
        const touched = { ...this.formState.touched };
        this.fieldConfig.forEach((field) => {
            if (this.visibleFields[field.name] === true) {
                touched[field.name] = true;
            }
        });
        this.formState = { ...this.formState, touched };
    }

    /**
     * Validates all visible fields.
     * @returns {Boolean} True when all visible fields are valid.
     */
    validateFields() {
        const errors = {};
        let isValid = true;
        this.fieldConfig.forEach((field) => {
            const error = this.validateVisibleField(field);
            errors[field.name] = error;
            if (error) isValid = false;
        });
        this.formState = { ...this.formState, errors, isValid };
        return isValid;
    }

    /**
     * Validates one field only when visible.
     * @param {Object} field - Normalized field config.
     * @returns {String|null} Error message.
     */
    validateVisibleField(field) {
        if (this.visibleFields[field.name] !== true) return null;
        const value = this.formState.values[field.name];
        return this.getFieldError(field, value);
    }

    /**
     * Resolves the first validation error for a field.
     * @param {Object} field - Normalized field config.
     * @param {*} value - Field value.
     * @returns {String|null} Error message.
     */
    getFieldError(field, value) {
        return (
            this.validateRequired(field, value) ||
            this.validateType(field, value) ||
            this.validateMinMaxLength(field, value)
        );
    }

    /**
     * Validates required field values.
     * @param {Object} field - Normalized field config.
     * @param {*} value - Field value.
     * @returns {String|null} Error message.
     */
    validateRequired(field, value) {
        if (!field.required || !this.isEmptyValue(value)) return null;
        return `${field.label} is required.`;
    }

    /**
     * Checks whether a value is empty for validation.
     * @param {*} value - Field value.
     * @returns {Boolean} True when empty.
     */
    isEmptyValue(value) {
        return value === '' || value === null || value === undefined || value === false;
    }

    /**
     * Runs type-specific validation.
     * @param {Object} field - Normalized field config.
     * @param {*} value - Field value.
     * @returns {String|null} Error message.
     */
    validateType(field, value) {
        if (this.isEmptyValue(value)) return null;
        if (field.type === 'email') return this.validateEmail(value);
        if (field.type === 'phone') return this.validatePhone(value);
        return null;
    }

    /**
     * Validates an email value.
     * @param {String} value - Email value.
     * @returns {String|null} Error message.
     */
    validateEmail(value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(value) ? null : 'Please enter a valid email address.';
    }

    /**
     * Validates a 10-digit phone value.
     * @param {String} value - Phone value.
     * @returns {String|null} Error message.
     */
    validatePhone(value) {
        const phoneRegex = /^\d{10}$/;
        return phoneRegex.test(value) ? null : 'Please enter a valid 10-digit phone number.';
    }

    /**
     * Validates minimum and maximum string lengths.
     * @param {Object} field - Normalized field config.
     * @param {*} value - Field value.
     * @returns {String|null} Error message.
     */
    validateMinMaxLength(field, value) {
        const stringValue = value === null || value === undefined ? '' : String(value);
        if (field.minLength && stringValue.length < field.minLength) {
            return `${field.label} must be at least ${field.minLength} characters.`;
        }
        return this.validateMaxLength(field, stringValue);
    }

    /**
     * Validates maximum string length.
     * @param {Object} field - Normalized field config.
     * @param {String} stringValue - String value.
     * @returns {String|null} Error message.
     */
    validateMaxLength(field, stringValue) {
        if (!field.maxLength || stringValue.length <= field.maxLength) return null;
        return `${field.label} must not exceed ${field.maxLength} characters.`;
    }

    /**
     * Builds a field view model for the template.
     * @param {Object} field - Normalized field config.
     * @returns {Object} Field view model.
     */
    buildFieldViewModel(field) {
        const error = this.formState.errors[field.name];
        const showError = Boolean(this.formState.touched[field.name] && error);
        return { ...field, ...this.getFieldRenderState(field, error, showError) };
    }

    /**
     * Returns render-only field state.
     * @param {Object} field - Normalized field config.
     * @param {String|null} error - Error message.
     * @param {Boolean} showError - Whether to show error.
     * @returns {Object} Render state.
     */
    getFieldRenderState(field, error, showError) {
        return {
            value: this.formState.values[field.name],
            checked: this.formState.values[field.name] === true,
            error,
            showError,
            inputId: `${field.name}-input`,
            errorId: `${field.name}-error`,
            ariaDescribedBy: showError ? `${field.name}-error` : null,
            formElementClass: this.getFormElementClass(showError),
            ...this.getFieldTypeFlags(field.type)
        };
    }

    /**
     * Returns CSS class for a form element.
     * @param {Boolean} showError - Whether field has visible error.
     * @returns {String} CSS class.
     */
    getFormElementClass(showError) {
        return showError ? 'slds-form-element slds-has-error' : 'slds-form-element';
    }

    /**
     * Returns template flags for a field type.
     * @param {String} fieldType - Field type.
     * @returns {Object} Type flags.
     */
    getFieldTypeFlags(fieldType) {
        return {
            inputType: INPUT_TYPE_BY_FIELD_TYPE[fieldType],
            isInput: Object.prototype.hasOwnProperty.call(INPUT_TYPE_BY_FIELD_TYPE, fieldType),
            isCheckbox: fieldType === 'checkbox',
            isTextarea: fieldType === 'textarea',
            isPicklist: fieldType === 'picklist'
        };
    }

    /**
     * Synchronizes every Flow output property.
     */
    syncAllOutputs() {
        this.syncFormDataOutput();
        this.syncStepValidOutput();
        this.syncWorkflowResponseOutput();
    }

    /**
     * Synchronizes form data JSON output.
     */
    syncFormDataOutput() {
        const nextValue = JSON.stringify(this.buildMergedFormData());
        this.dispatchOutputChange('formDataJson', nextValue);
    }

    /**
     * Builds merged form data from existing input plus current state.
     * @returns {Object} Merged form data.
     */
    buildMergedFormData() {
        return {
            ...this.getExistingDataSnapshot(),
            ...this.formState.values
        };
    }

    /**
     * Parses existing data as a defensive merge base.
     * @returns {Object} Existing data snapshot.
     */
    getExistingDataSnapshot() {
        if (!this._existingDataJson) return {};
        const parsedData = this.parseJsonSafely(this._existingDataJson, {});
        return parsedData && !Array.isArray(parsedData) ? parsedData : {};
    }

    /**
     * Synchronizes validity output.
     */
    syncStepValidOutput() {
        this.dispatchOutputChange('isStepValid', this.formState.isValid);
    }

    /**
     * Synchronizes workflow response output.
     */
    syncWorkflowResponseOutput() {
        const response = this.buildWorkflowResponse();
        this.dispatchOutputChange('workflowResponseJson', JSON.stringify(response));
    }

    /**
     * Builds the workflow response object.
     * @returns {Object} Workflow response.
     */
    buildWorkflowResponse() {
        return {
            workflowType: this._workflowType,
            currentStep: this._currentStep,
            submittedAt: this.getSubmittedAt(),
            formData: this.buildMergedFormData()
        };
    }

    /**
     * Returns the current timestamp without milliseconds.
     * @returns {String} ISO-like timestamp.
     */
    getSubmittedAt() {
        return new Date().toISOString().split('.')[0];
    }

    /**
     * Dispatches a Flow output change only when changed.
     * @param {String} propertyName - Output property name.
     * @param {*} propertyValue - Output property value.
     */
    dispatchOutputChange(propertyName, propertyValue) {
        if (this[propertyName] === propertyValue) return;
        this[propertyName] = propertyValue;
        this.dispatchFlowAttributeChange(propertyName, propertyValue);
    }

    /**
     * Dispatches FlowAttributeChangeEvent safely.
     * @param {String} propertyName - Output property name.
     * @param {*} propertyValue - Output property value.
     */
    dispatchFlowAttributeChange(propertyName, propertyValue) {
        try {
            this.dispatchEvent(new FlowAttributeChangeEvent(propertyName, propertyValue));
        } catch (error) {
            this.logError(`Failed to dispatch ${propertyName}.`, error);
        }
    }

    /**
     * Logs recoverable errors without interrupting rendering.
     * @param {String} message - Error message.
     * @param {Error} error - Error object.
     */
    logError(message, error) {
        // eslint-disable-next-line no-console
        console.error(message, error);
    }

    /**
     * Logs recoverable warnings without interrupting rendering.
     * @param {String} message - Warning message.
     */
    logWarning(message) {
        // eslint-disable-next-line no-console
        console.warn(message);
    }
}
