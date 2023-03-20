

/* DATA CLEANING USING SQL QUERIES */


SELECT *
FROM NashvilleHousing

-------------------------------------------------------------------------------

--Standardize data format(from DateTime to Date)

SELECT SaleDate,CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing 

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)


--Didn't work, alternatively


ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date; 

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)



--Populate property address

SELECT PropertyAddress, ParcelID
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID   --a closer look shows that properties with same ParcelID will 99% of the time have same PropertyAddress

SELECT Nash1.ParcelID, Nash1.PropertyAddress, Nash2.ParcelID, Nash2.PropertyAddress, ISNULL(Nash1.PropertyAddress,Nash2.PropertyAddress)
FROM NashvilleHousing AS Nash1
JOIN NashvilleHousing AS Nash2   --doing a self-join
  ON Nash1.ParcelID = Nash2.ParcelID
  AND Nash1.[UniqueID ] <> Nash2.[UniqueID ]     --unique identifiers for each property
WHERE Nash1.PropertyAddress IS NULL

UPDATE Nash1      
SET PropertyAddress = ISNULL(Nash1.PropertyAddress,Nash2.PropertyAddress)  --populates the nulls with PropertyAddress where it'sgiven
FROM NashvilleHousing AS Nash1
JOIN NashvilleHousing AS Nash2   --doing a self-join
  ON Nash1.ParcelID = Nash2.ParcelID
  AND Nash1.[UniqueID ] <> Nash2.[UniqueID ]   
WHERE Nash1.PropertyAddress IS NULL



--Split address into individual columns (address, city, state)

SELECT PropertyAddress
FROM NashvilleHousing --delimiter that separates the address & city is a comma

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS city
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD PropertyAddressSplit nvarchar(255); 

UPDATE NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertyCitySplit nvarchar(255); 

UPDATE NashvilleHousing
SET PropertyCitySplit = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))


--substring() can split addresses in OwnerAddress too, but we'll use parsename() as an alternative

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddressSplit,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCitySplit,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerStateSplit
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerAddressSplit nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerCitySplit nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerCitySplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerStateSplit nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerStateSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



--Change Y & N to Yes & No in the SoldAsVacant column

SELECT DISTINCT (SoldAsVacant),COUNT(SoldAsVacant)   --the mixture is Y, N, Yes, No
FROM NashvilleHousing   
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


--Remove duplicates

WITH RowNumCTE AS (
SELECT *,
   ROW_NUMBER() OVER (
   PARTITION BY ParcelID,
                PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
				   UniqueID) AS row_num
FROM NashvilleHousing
--ORDER BY ParcelID
--WHERE row_num > 1
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--Resulted to some 104 rows 

WITH RowNumCTE AS (
SELECT *,
   ROW_NUMBER() OVER (
   PARTITION BY ParcelID,
                PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
				   UniqueID) AS row_num
FROM NashvilleHousing
--ORDER BY ParcelID
--WHERE row_num > 1
)
DELETE     --Deleted the 104 duplicate rows
FROM RowNumCTE
WHERE row_num > 1



--Delete Unused columns

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, TaxDistrict

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate