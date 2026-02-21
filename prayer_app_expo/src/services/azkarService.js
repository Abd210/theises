import azkarData from '../../assets/data/azkar.json';

export const getAzkarCategories = () => {
    return azkarData.map(c => ({
        id: c.id,
        name: c.name,
        icon: c.icon,
        count: c.items.length
    }));
};

export const getAzkarByCategory = (categoryId) => {
    return azkarData.find(c => c.id === categoryId)?.items || [];
};
