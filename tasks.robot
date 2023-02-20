*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.

# ...    Saves the order HTML receipt as a PDF file.
# ...    Saves the screenshot of the ordered robot.
# ...    Embeds the screenshot of the robot to the PDF receipt.
# ...    Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Read vault
    Input form dialog
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Log    ${row}
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Take a screenshot of the robot    ${row}
        ${filename}=    Store the receipt PDF file    ${row}
        Embed the robot screenshot to the receipt PDF file    ${filename}
        Go to order another robot
    END
    Read vault
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    browser_selection=firefox,chrome

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Wait Until Element Is Visible    class:modal-body
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Wait Until Keyword Succeeds    5x    strict: 100ms    Assert order succeeded

Assert order succeeded
    Click Button    Order
    Wait Until Page Contains    Receipt

Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${row}[Order number].png

Store the receipt PDF file
    [Arguments]    ${row}
    ${html}=    Get Element Attribute    id:receipt    outerHTML
    Log    ${html}
    Html To Pdf    ${html}    ${OUTPUT_DIR}${/}${row}[Order number].pdf
    RETURN    ${OUTPUT_DIR}${/}${row}[Order number]

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${filename}
    ${files}=    Create List    ${filename}.png
    Add Files To pdf    ${files}    ${filename}.pdf    apprend=${True}
    Close All Pdfs

Go to order another robot
    Click Button    Order another robot

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}pdfs.zip    include=*.pdf

Read vault
    ${secret}=    Get Secret    random
    Log    ${secret}[first]
    Log    ${secret}[second]

Input form dialog
    Add heading    Input any text....
    Add text input    message
    ${result}=    Run dialog
    #dont actually want the input...
    Log    ${result.message}
