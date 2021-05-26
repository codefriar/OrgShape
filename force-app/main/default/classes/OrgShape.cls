/**
 * @description Class contains static methods for determining if specific
 * platform features are enabled. For example, do we have platform cache
 * enabled. You could also write similar methods for experiences.
 *
 * @group Shared Code
 */
public with sharing class OrgShape {
    @TestVisible
    private String safeDefaultCachePartition;
    
    @TestVisible
    private Organization orgShape;

    public Boolean isSandbox {
        get {
            return getOrgShape().isSandbox;
        }
    }

    public Boolean multiCurrencyEnabled {
        get{
            return UserInfo.isMultiCurrencyOrganization();
        }
    }

    public String orgType { 
        get {
            return getOrgShape().OrganizationType;
        }
    }

    public Boolean isReadOnly {
        get {
            return getOrgShape().isReadOnly;
        }
    }

    public String instanceName {
        get {
            return getOrgShape().instanceName;
        }
    }

    public String podName {
        get {
            return instanceName;
        }
    }

    public Integer getFiscalYearStartMonth {
        get {
            return getOrgShape().fiscalYearStartMonth;
        }
    }

    public Boolean lightningEnabled {
        get{
            return UserInfo.getUiThemeDisplayed().containsIgnoreCase('theme4');
        }
    }

    public Id id {
        get {
            return getOrgShape().id;
        }
    }

    public String locale{
        get {
            return getOrgShape().languageLocaleKey;
        }
    }

    public String name {
        get {
            return getOrgShape().name;
        }
    }

    public String timeZoneKey{
        get{
            return getOrgShape().timeZoneSidKey;
        }
    }

    /**
     * @description Method determines if platform cache is enabled for this org
     * Note: fail-safes to false.
     * Note: Allows override by setting OrgShape.disablePlatformCache
     * equal to true. Use this in test contexts where cache is not available like
     * when you have to use seeAllData=true
     * @return      `Boolean`
     */
    public Boolean isPlatformCacheEnabled() {
        String defaultCachePartition = queryForDefaultCachePartition();
        if (isSeeAllDataTrue() || defaultCachePartition == null) {
            return false;
        }

        Boolean cacheAvailable = false;
        try {
            Cache.Org.getPartition(defaultCachePartition).getCapacity();
            cacheAvailable = true;
        } catch (Exception ex) {
            system.debug(LoggingLevel.WARN, 'Failed to get orgCache');
        }
        return cacheAvailable;
    }

    /**
     * @description Certain features of the platform are incompatible with
     * data-siloed tests. These features require testing with the annotation
     * @test(seeAllData=true). Other platform features are incompatible with
     * seeAllData=true. When used in a test context, this method determines if
     * the currently running test is executing with, or without seeAllData=true.
     *
     * This method is therefore used to automatically disable platform features
     * that require are incompatible with seeAllData=true. For example: platform
     * cache is incompatible with seeAllData=true. However, our security
     * library, CanTheUser utilizes platform cache to accelerate Crud and FLS
     * checks. CanTheUser uses this method, in part, to determine, transparently
     * if it should utilize platformCache during test execution
     *
     * Note: It is not a good idea, and against best practices to use
     * seeAllData=true when not absolutely necessary.
     * @return      `Boolean`
     */
    @TestVisible
    private Boolean isSeeAllDataTrue() {
        Boolean seeAllData = false;
        if (!Test.isRunningTest()) {
            return seeAllData; // This line is not testable :(
        }

        try {
            // this will throw an exception in a data-siloed test.
            ConnectApi.ChatterUsers.getFollowings(
                null,
                String.valueOf(UserInfo.getUserId())
            );
            seeAllData = true;
        } catch (UnsupportedOperationException UE) {
            // this means seeAllData != true
            System.debug(
                LoggingLevel.INFO,
                'Caught UnsupportedOperationException'
            );
        }
        return seeAllData;
    }

    /**
     * @description This method is responsible for discovering a cache partition
     * that can be used for determining if platformCache is enabled and
     * configured.
     *
     * Note: This method memoizes the result of the query, ensuring that the
     * underlying soql query is only ever run once per transaction.
     *
     * @return      `String`
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private String queryForDefaultCachePartition() {
        if (this.safeDefaultCachePartition != null) {
            return this.safeDefaultCachePartition;
        }
        try {
            PlatformCachePartition partition = [
                SELECT developerName
                FROM PlatformCachePartition
                WHERE NamespacePrefix = ''
                LIMIT 1
            ];
            this.safeDefaultCachePartition =
                'local.' + partition.DeveloperName;
        } catch (System.QueryException qe) {
            System.debug(
                LoggingLevel.WARN,
                'Caught QueryException looking for cache partition'
            );
        }
        return this.safeDefaultCachePartition;
    }

    /**
     * @description Uses a dynamic soql query to determine if Advanced 
     * MultiCurrency Management is enabled. Note, this must be a dynamic soql
     * query because referencing DatedConversionRate will not compile in orgs
     * without Advanced MultiCurrency Management enabled.
     * 
     * Note: This was originally written by the NPSP team and can be found here:
     * https://github.com/SalesforceFoundation/NPSP/blob/aad20ffb747ecda9a037c4bce9cd19617b6a727b/src/classes/UTIL_Currency.cls#L79
     * @return      `Boolean`
     */
    public Boolean advancedMultiCurrencyManagementEnabled(){
        Boolean isACMEnabled = false;
        if (this.multiCurrencyEnabled) {
            try {
                Integer datedConversionRateCount = Database.query('SELECT Id FROM DatedConversionRate LIMIT 1').size();
                if (datedConversionRateCount == 1) {
                    isACMEnabled = true;
                }
            } catch (Exception e) {
                // Nothing to do, ACM = false
            }
        }
        return isACMEnabled;
    }

    /// HELPER METHODS

    private Organization getOrgShape(){
        if(this.OrgShape != null){
            return this.orgShape;
        } else {
            this.orgShape = [
                SELECT FIELDS(STANDARD)
                FROM Organization
                LIMIT 1
            ];
        }
        return this.orgShape;
        
    }
}
