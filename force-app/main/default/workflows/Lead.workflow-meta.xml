<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Auto_Response_on_Lead_Creation</fullName>
        <description>Auto Response on Lead Creation</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>ELFI_Email_Templates/ELFIWebtoLeademailresponse</template>
    </alerts>
    <alerts>
        <fullName>Internal_Email_for_New_Lead_Creation</fullName>
        <ccEmails>info@easylegal.ca</ccEmails>
        <description>Internal Email for New Lead Creation</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/LeadsNewassignmentnotificationSAMPLE</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Company_Name_First_Last_Name</fullName>
        <field>Company</field>
        <formula>FirstName &amp;&quot; &quot;&amp; LastName &amp;&quot; - &quot; &amp; Text(Account__c)</formula>
        <name>Set Company Name = First &amp; Last Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Lead_Source_to_Web_Form</fullName>
        <field>LeadSource</field>
        <literalValue>Web Form</literalValue>
        <name>Set Lead Source = Web Form</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Lead auto response</fullName>
        <actions>
            <name>Auto_Response_on_Lead_Creation</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Internal_Email_for_New_Lead_Creation</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Email</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.CreatedById</field>
            <operation>equals</operation>
            <value>Larry Herscu</value>
        </criteriaItems>
        <description>Send email to lead upon creation</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Company Name %3D First %26 Last Name %26 Account %23</fullName>
        <actions>
            <name>Set_Company_Name_First_Last_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.RecordTypeId</field>
            <operation>equals</operation>
            <value>Customer Record Type</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Lead Source to Web Form</fullName>
        <actions>
            <name>Set_Lead_Source_to_Web_Form</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Web_To_Lead_From__c</field>
            <operation>equals</operation>
            <value>Application Form</value>
        </criteriaItems>
        <description>Web To Lead From = Application</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
