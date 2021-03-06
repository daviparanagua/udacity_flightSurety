const statuses = [0, 10, 20, 30, 40, 50];

function getRandomInt(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min)) + min;
  }

export default [
    {
        id: '1234',
        from: 'GIG',
        to: 'SDU',
        departure: new Date(Date.now + 1000 * 60 * 60 * 2),
        status: statuses[getRandomInt(0,5)]
    },
    {
        id: '1245',
        from: 'GIG',
        to: 'CGH',
        departure: new Date(Date.now + 1000 * 60 * 60 * 3),
        status: statuses[getRandomInt(0,5)]
    },
    {
        id: '4534',
        from: 'CGH',
        to: 'SDU',
        departure: new Date(Date.now + 1000 * 60 * 60 * 4),
        status: statuses[getRandomInt(0,5)]
    },
    {
        id: '4512',
        from: 'CGH',
        to: 'GIG',
        departure: new Date(Date.now + 1000 * 60 * 60 * 5),
        status: statuses[getRandomInt(0,5)]
    }
]