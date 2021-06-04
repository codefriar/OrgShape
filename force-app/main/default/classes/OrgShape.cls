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
    private Organization orgShape = getOrgShape();

    /**
     * @description property reports whether this transaction took place
     * in a sandbox.
     */
    public Boolean isSandbox {
        get {
            return getOrgShape().isSandbox;
        }
    }

    /**
     * @description reports whether or not this transaction took place in an
     * org with multiCurrency enabled.
     * Note: I have no idea why the underlying method is on UserInfo.
     */
    public Boolean multiCurrencyEnabled {
        get {
            return UserInfo.isMultiCurrencyOrganization();
        }
        private set {
        }
    }

    /**
     * @description reports whether this transaction took place in an org with
     * a namespace prefix
     */
    public Boolean hasNamespacePrefix {
        get {
            return String.isNotBlank(getOrgShape().NamespacePrefix);
        }
    }

    /**
     * @description reports the namespace prefix of this org. May return null;
     */
    public String namespacePrefix {
        get {
            return getOrgShape().NamespacePrefix;
        }
    }

    /**
     * @description reports this org's type. ie: 'Developer Edition'
     */
    public String orgType {
        get {
            return getOrgShape().OrganizationType;
        }
    }

    /**
     * @description reports the read-only status.
     * this is a proxy for 'is this org active'
     */
    public Boolean isReadOnly {
        get {
            return getOrgShape().isReadOnly;
        }
    }

    /**
     * @description returns the instance name.
     * In practice not null.
     */
    public String instanceName {
        get {
            return getOrgShape().instanceName;
        }
    }

    /**
     * @description convenience method. Alias for instanceName
     */
    public String podName {
        get {
            return instanceName;
        }
    }

    /**
     * @description returns this org's fiscal year starting month
     */
    public Integer getFiscalYearStartMonth {
        get {
            return getOrgShape().fiscalYearStartMonth;
        }
    }

    /**
     * @description reports the users' displayed theme.
     */
    public Boolean lightningEnabled {
        get {
            return UserInfo.getUiThemeDisplayed().containsIgnoreCase('theme4');
        }
    }

    /**
     * @description reports the org's ID.
     * in practice, this is a constant
     */
    public Id id {
        get {
            return getOrgShape().id;
        }
    }

    /**
     * @description reports the org's locale
     */
    public String locale {
        get {
            return getOrgShape().languageLocaleKey;
        }
    }

    /**
     * @description reports the org's name
     */
    public String name {
        get {
            return getOrgShape().name;
        }
    }

    /**
     * @description reports the timeZoneSidKey
     */
    public String timeZoneKey {
        get {
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
    public Boolean isSeeAllDataTrue() {
        return Test.isRunningTest() ? isSeeAllDataDuringTest() : false;
    }

    private Boolean isSeeAllDataDuringTest() {
        Boolean seeAllData = false;
        try {
            // this will throw an exception in a data-siloed test.
            ConnectApi.ChatterUsers.getFollowings(
                null,
                String.valueOf(UserInfo.getUserId())
            );
            seeAllData = true;
        } catch (UnsupportedOperationException UE) {
            // this means seeAllData == false
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
            this.safeDefaultCachePartition = 'local.' + partition.DeveloperName;
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
     * It handles the QueryException that is thrown when the feature is
     * disabled.
     *
     * Note: This was originally written by the NPSP team and can be found here:
     * https://github.com/SalesforceFoundation/NPSP/blob/aad20ffb747ecda9a037c4bce9cd19617b6a727b/src/classes/UTIL_Currency.cls#L79
     * @return      `Boolean`
     */
    public Boolean isAdvancedMultiCurrencyManagementEnabled() {
        Boolean isACMEnabled = false;
        if (this.multiCurrencyEnabled) {
            try {
                Integer datedConversionRateCount = Database.query(
                        'SELECT Id FROM DatedConversionRate LIMIT 1'
                    )
                    .size();
                if (datedConversionRateCount == 1) {
                    isACMEnabled = true;
                }
            } catch (QueryException e) {
                // sObject type 'DatedConversionRate' is not supported.
                // Nothing to do, ACM = false
            }
        }
        return isACMEnabled;
    }

    /// HELPER METHODS

    /**
     * @description Private method that memoizes the query result
     * Suppressing the PMD warning to validate crud permissions before
     * DML, because the Organization Object is always available.
     * @return      `Organization`
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Organization getOrgShape() {
        if (this.OrgShape != null) {
            return this.orgShape;
        } else {
            this.orgShape = [SELECT FIELDS(STANDARD) FROM Organization LIMIT 1];
        }
        return this.orgShape;
    }
}
