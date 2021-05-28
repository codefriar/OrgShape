
# OrgShape

OrgShape is a delightful and elegant way to inspect your org within Apex. It surfaces the standard Organziation object details as class properties. Additionally, it provides methods for determining other things. For instance, whether or not your org has Platform Cache enabled or whether the current execution context is a `SeeAllData=true` unit test.

> OrgShape is a library extraction from [Apex Recipes](https://www.github.com/trailheadapps/apex-recipes)


## Badges

[![License: CC0-1.0](https://img.shields.io/badge/License-CC0%201.0-orange.svg)](http://creativecommons.org/publicdomain/zero/1.0/)
[![CI Workflow](https://github.com/codefriar/OrgShape/workflows/CI/badge.svg)](_https://github.com/codefriar/OrgShape/actions?query=workflow%3ACI_)
[![Packaging Workflow](https://github.com/codefriar/OrgShape/workflows/Packaging/badge.svg)](_https://github.com/codefriar/OrgShape/actions?query=workflow%3APackaging_) [![codecov](https://codecov.io/gh/codefriar/OrgShape/branch/main/graph/badge.svg)](_https://codecov.io/gh/codefriar/OrgShape_)
[![Twitter](https://img.shields.io/twitter/follow/Codefriar.svg?style=social)](https://img.shields.io/twitter/follow/Codefriar.svg?style=social)
## Contributing

Contributions are always welcome!

See [`contributing.md`](https://github.com/codefriar/OrgShape/blob/main/CONTRIBUTION.md) for ways to get started.

Please adhere to this project's [`code of conduct`](https://github.com/codefriar/OrgShape/blob/main/CONTRIBUTION.md).

  
## Installation

To install or deploy OrgShape you have three options:

1. SPM Install: This is the preferred method, [but it requires SPM. Find out more here.](https://spm-registry.herokuapp.com/) 
``` sfdx spm:install -n 'OrgShape' ```
1. Package Link: Click [this link](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5e000000u199AAA) to install the OrgShape unlocked package in your org.
2. Git Clone: This is an exercise left to the reader.

## Usage/Examples

### Determine your org's ID
```apex
Id orgId = new OrgShape().Id;
```

### Check if this org is Multi-Currency enabled
```apex
Boolean isMultiCurrencyOrg = new OrgShape().multiCurrencyEnabled;
```

### List of exposed Organization properties
> Note, these properties are all exposed from a Soql query to the Organization object. The query is memoized, so multiple checks of Organization properties within the same transaction only incur a single SOQL Query cost.
These properties are all accessed the same way, using this formula:
```apex
new OrgShape().<<PROPERTYNAME>>
```
Full list of properties:
- `orgShape.isSandbox`
- `orgShape.multiCurrencyEnabled`
- `orgShape.orgType`
- `orgShape.isReadOnly`
- `orgShape.instanceName`
- `orgShape.podName`
- `orgShape.getFiscalYearStartMonth`
- `orgShape.id`
- `orgShape.locale`
- `orgShape.timeZoneKey`
- `orgShape.name`
- `orgShape.namespacePrefix`

## Exposed Methods
OrgShape exposes methods that determine feature availability or execution context through logically derived methods. For instance, determining if PlatformCache is enabled must be deduced by looking at *other* objects and aspects of the org. 

### Determine if Platform Cache is enabled *and* available
```apex
Boolean platformCacheEnabled = new OrgShape().isPlatformCacheEnabled();
```

### Determine if the current transaction Quiddity `SeeAllData=true`
```apex
Boolean isCodeyCrying = new OrgShape().isSeeAllDataTrue();
```

### Determine if Advanced Multi-Currency Management is enabled
```
Boolean advMultiCurrencyMangagement = new OrgShape().isAdvancedMultiCurrencyManagementEnabled();
```
## Acknowledgements

- [Apex Recipes](https://www.github.com/trailheadapps/apex-recipes)
- [NPSP - (Non Profit Success Pack)](https://github.com/SalesforceFoundation/NPSP)