*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium    #auto_close=${False}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    10x    1s    Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    headless=True

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${robot_orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${robot_orders}

Close the annoying modal
    Wait Until Element Is Visible    css:button.btn-danger
    Click Button    css:button.btn-danger

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order
    Wait Until Page Contains Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${order_id}=    Get Element Attribute    //html/body/div/div/div[1]/div/div[1]/div/div/p[1]    innerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}tmp/receipt_${row}.pdf
    ${pdf_details}=    Create List
    ...    ${order_id}
    ...    receipt_${row}
    RETURN    ${pdf_details}

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Page Contains Element    robot-preview-image
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}tmp/screenshot_${row}.png
    RETURN    screenshot_${row}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To PDF
    ...    image_path=${OUTPUT_DIR}${/}tmp/${screenshot}.png
    ...    source_path=${OUTPUT_DIR}${/}tmp/${pdf}[1].pdf
    ...    output_path=${OUTPUT_DIR}${/}orders/${pdf}[0].pdf

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders    ${OUTPUT_DIR}${/}orders.zip
