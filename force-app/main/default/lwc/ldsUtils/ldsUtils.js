/**
 * Reduces one or more LDS errors into a string[] of error messages.
 * @param {FetchResponse|FetchResponse[]} errors
 * @return {String[]} Error messages
 */
export function reduceErrors(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return (
        errors
            // Remove null/undefined items
            .filter(error => !!error)
            // Extract an error message
            .map(error => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message);
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error shape so try HTTP status text
                return error.statusText;
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter(message => !!message)
    );
}

export function generateDataTableErrors(errorRecords, updatedRecords) {
    // Write code to generate errors here...
    /*
    [
        {
            Id: 'record_id',
            errors: [
                {
                    fields: ['field_name1', 'field_name2'],
                    message: 'error message...'
                }
                ...
            ]
        }
        ...
    ]


    triggerError(event) {
           this.errors = {
                rows: {
                    <id>: {
                        title: 'We found 2 errors.',
                        messages: [
                            'Enter a valid amount.',
                            'Verify the email address and try again.'
                        ],
                        fieldNames: ['amount', 'contact']
                    }
                },
                table: {
                    title: 'Your entry cannot be saved. Fix the errors and try again.',
                    messages: [
                        'Row 2 amount must be number',
                        'Row 2 email is invalid'
                    ]
                }
            };
        }
    */
    let dtErrors = {
        rows: {},
        table: {
            title: 'Your entry cannot be saved. Please fix the errors and try again.',
            messages: []
        }
    }

    errorRecords.forEach(errorRecord => {
        let row = dtErrors.rows[errorRecord.Id] || {title: '', messages: [], fieldNames: []};
        let rowNumber = updatedRecords.findIndex(record => {return record.Id === errorRecord.Id}) + 1;

        errorRecord.errors.forEach(error => {
            dtErrors.table.messages.push(`Row ${rowNumber}: ${error.message}`);
            row.messages.push(error.message);
            row.fieldNames.push(error.fields[0]);
        })
        row.title = `Found ${row.messages.length} errors.`;
        dtErrors.rows[errorRecord.Id] = row;
    });

    return dtErrors;
}