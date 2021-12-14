# Flatten Hierarchies About

**Hierarchies are everywhere**, they can represent a *bill of materials, company relationships, company structure, geographic zones, product categorization, etc.* And are a natural way to aggregate detailed information before going deep into details.

Hierarchies are usually represented in tabular form in either a *four column table*, or a *three column table* in transactional systems. Being the **3 column table** the **canonical way** to represent them.

When building reports based on a Star Schema a common way to handle a these relationships is using a technique called *flattening* which converts this 3 column table in a set of columns ready to be added to the dimension table and use them as grouping columns to look-up or look-down across the hierarchy.

These two functions are meant que speed things up as soon as you find a hierarchy.

## Four vs. Three column hierarchy table

The **4 column hierarchy** table:
* Has a line for each relationship in the hierarchy.
* Root nodes don't get their own line.
* The *parent name* column is needed because we need a way to name root nodes.

The **3 column hierarchy** table:
* Has a line for each node in the hierarchy.
* Root nodes get their own line.
* Root nodes will have either *null* or *blank* values in their ParentKey column.

# Functions

## fx4to3.pq

> Converts a 4 column hierarchy into a 3 column hierarchy.

Variables:
* **SourceTable** as *table*, A table with four columns that represent a hiearchy.
* **NodeKey** as *text*, A text with the *name of the column* which holds node key values.
* **NodeName** as *text*, A text with the *name of the column* which holds node name values.
* **ParentKey** as *text*, A text with the *name of the column* which holds parent key values.
* **ParentName** as *text*, A text with the *name of the column* which holds parent name values.

Returns:
* A table with the 4 column hiearchy converted to a 3 column hierarchy.

Pending Improvements:
* Does not carry original types through the algorithm.
* Handle value proportions between parent-child relationships.

## fxFlatten.pq

> Flattens from rows in a 3 column hierarchy to as many columns as levels present.

This function flattens a table based on Chapter 10 Recursive hierarchies and bridges from [Star Schema: Complete Reference by Chris Adamson](http://chrisadamson.com/star-schema-complete-reference)

Variables:
* **HierarchyTable** as *table*, A table with three columns that represent a hierarchy.
* **NodeKey** as *text*, A text with the *name of the column* which holds node key values.
* **NodeName** as *text*, A text with the *name of the column* which holds de node name values.
* **ParentKey** as *text*, A text with the *name of the column* which holds parent key values.

Returns: 
A table with the columns:
* **Node_ID**, Hierarchy nodes ID column.
* **Node_Name**, Hierarchy nodes name column.
* **NodeKey_### (*n)**, As many columns as levels are in the hierarchy, holding the key value for the parent node that corresponds to the ### level in the current node path. Each column is named after the depth level with zero left padded number up to three numbers.
* **NodeName_### (*n)**, The same as *NodeKey_###* but instead of key values holds name values.
* **NodeDepth**, *Integer* indicating the depth level of the current node.
* **Path**, *Text* string representing the path from the root node to the current node.
* **IsLeaf**, *Boolean* value indicating if the current node is at the end of the hierarchy.

Pendint improvements:
* Does not carry original types through the algorithm.
* Handle value proportions between parent-child relationships.

## fxBridge.pq

> Generates a bridge table that can be used between fact table and dimension table.

This function defines a bridge table based on: Chapter 10 Recursive hierarchies and bridges from [Star Schema: Complete Reference by Chris Adamson](http://chrisadamson.com/star-schema-complete-reference)

The basic definition of it is:
* Each row captures a relationship between a pair of rows.
* Bridge has two foreign keys that refer to the dimension. One that represents the *higher level entity*, and another that represents the *lower level entity*.
* A bridge not only contains rows for direct relationships. It also contains rows that represent indirect relationships where node are more than one level apart from each other.

Variables:
* **HierarchyTable** as *table*, A table with three columns that represent a hierarchy.
* **NodeKey** as *text*, A text with the *name of the column* which holds node key values.
* **NodeName** as *text*, A text with the *name of the column* which holds de node name values.
* **ParentKey** as *text*, A text with the *name of the column* which holds parent key values.

Returns:
A table with the columns
* **Predecessor**, A column that identifies the superior key in a node relationship.
* **Successor**, A column that identifies the subordinate key in a node relationship.
* **Levels Removed**, A column that quantifies the level distance between the two node relationship.

Pending improvements:
* Currently does not handle recursive hierarchies.
* Multi-parent is handled as if all nodes that have multiple parents have them the same number of levels away. If its not the case the results will be incorrect.
* Does not carry original types through the algorithm.
* Handle value proportions between parent-child relationships.

# How To Use

Work in progress

# Disclaimer