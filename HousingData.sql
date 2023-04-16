SELECT * FROM `nashville.housing`.housingdata;housingdata


-- Populate property address where address in NULL
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress) 
From housingdata AS a
Join housingdata AS b
On a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null ; 

-- Updating the table to refill empty spaces in column PropertyAddress
UPDATE housingdata AS a
JOIN housingdata AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Breaking address into individuals columns adress and city
SELECT SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,
SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City
FROM housingdata;

-- Adding new columns that we created above, Address and City from PropertyAddress
ALTER TABLE housingdata
ADD SplittedAddress VARCHAR(255) ; 

UPDATE housingdata 
SET SplittedAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

ALTER TABLE housingdata
ADD SplittedCity VARCHAR(255) ;

UPDATE housingdata
SET SplittedCity = SUBSTRING_INDEX(PropertyAddress, ',', -1) 

-- Breaking OwnerAddress into individuals columns adress, city and state
SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
FROM housingdata;

--  Adding new columns that we createt above, address,City and State from OwnerAddress

-- Adding address
ALTER TABLE housingdata
ADD OwnerSplitAddress VARCHAR(255) ;

UPDATE housingdata
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1)

-- Adding City
ALTER TABLE housingdata
ADD OwnerSplitCity VARCHAR(255) ;

UPDATE housingdata
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)

-- Adding State
ALTER TABLE housingdata
ADD OwnerSplitState VARCHAR(255) ;

UPDATE housingdata
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1)

-- Change Y and N to Yes and No in "Sold as Vacant" field
Select Distinct SoldAsVacant, Count(SoldAsVacant)
from housingdata
Group by SoldAsVacant
Order by 2

-- Creating CASE statment 
Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END AS YesNo
FROM housingdata ;

-- Updating the column SoldAsVacant
UPDATE housingdata
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END 

-- Finding duplicate data 
WITH RowNumberCTE AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
    FROM housingdata
)
Select *
FROM RowNumberCTE
Where row_num > 1 

-- Subquery in order to delete duplicate values
DELETE FROM housingdata
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
            ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
        FROM housingdata
    ) AS RowNumberCTE
    WHERE row_num > 1
);
