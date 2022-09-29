*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Variables ***
${WEBSITE_URL}


*** Tasks ***
Get url from Vault and set as Global Variable
    ${url}=    Get Secret    url
    ${WEBSITE_URL}=    Set Variable    ${url}[website_url]
    Set Global Variable    ${WEBSITE_URL}    ${WEBSITE_URL}

Order robots from RobotSpareBin Industries Inc
    Open website
    ${orders}=    Download orders file
    FOR    ${row}    IN    @{orders}
       Give consent
       Fill in the order form    ${row}
       Preview the order
       Wait Until Keyword Succeeds    5x    1s    Submit order
       ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
       ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
       Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
       Order next robot
    END
    Create receipts ZIP file
    [Teardown]    Close Browser


*** Keywords ***
Download orders file
    Add heading    Please give orders urls
    Add text    Hint: https://robotsparebinindustries.com/orders.csv
    Add text input    orders_url
    ${result}=    Run dialog
    Download    ${result.orders_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Open website
    Open Available Browser    ${WEBSITE_URL}    headless=False

Give consent
    Click Button    OK

Fill in the order form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    xpath://*[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    xpath://*[@id="address"]    ${row}[Address]

Preview the order
    Click Button    Preview

Submit order
    Click Button    order
    Page Should Contain Element    id:order-completion

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf
    ...    ${receipt_html}
    ...    ${OUTPUT_DIR}${/}receipts${/}${Order number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}${Order number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Capture Element Screenshot
    ...    id:robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}${Order number}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}${Order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Order next robot
    Click Button    Order another robot

Create receipts ZIP file
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
